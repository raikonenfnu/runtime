// Copyright 2020 The TensorFlow Runtime Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//===- tensor_shape.cc ----------------------------------------------------===//
//
// This file implements TensorShape.
//
//===----------------------------------------------------------------------===//

#include "tfrt/tensor/tensor_shape.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Compiler.h"
#include "llvm/Support/raw_ostream.h"
#include "tfrt/support/error_util.h"
#include "tfrt/support/forward_decls.h"

namespace tfrt {

raw_ostream& operator<<(raw_ostream& os, const TensorShape& value) {
  os << '[';
  SmallVector<ssize_t, 8> dims;
  value.GetDimensions(&dims);
  if (!dims.empty()) {
    os << dims[0];
    for (size_t i = 1, e = dims.size(); i != e; ++i) os << ", " << dims[i];
  }
  return os << ']';
}

TensorShape::TensorShape(ArrayRef<ssize_t> dims) {
  assert(dims.size() < 256 && "Can only handle rank up to 255");
  auto rank = static_cast<uint8_t>(dims.size());

  // We zero-initialize to ensure the representation value is determinsitic.
  memset(&representation_, 0, sizeof(representation_));

  // This code aims to make the common rep16 case perform the fewest comparisons
  // by speculating it will be fine.  It is slightly slower for rep32, and makes
  // the worst case scenario do the most comparisons.
  size_t next_dim = 0;

  // Scan all the dims breaking out if a dim is found larger than 16-bit.
  while (true) {
    if (next_dim == rank) {
      // Ok, all the dims fit in 16-bits.  We can use the Rep16 format if we
      // have 7 or fewer dims.
      if (rank > 7) break;

      for (size_t i = 0; i != rank; ++i) {
        representation_.rep16.dims[i] = uint16_t(dims[i]);
      }
      representation_.rep16.kind = RepKind::kRep16;
      representation_.rep16.rank = rank;
      return;
    }

    // If this dimension fits in 16 bits, then keep scanning.
    auto this_dim = dims[next_dim];
    if (uint16_t(this_dim) != this_dim) break;
    ++next_dim;
  }

  // Okay, we found a dimension too big to fit into rep16 - check for rep32.
  while (true) {
    if (next_dim == rank) {
      // Ok, all the dims fit in 32-bits.  We can use the Rep32 format if we
      // have 4 or fewer dims and if the last dim fits in 16-bits.
      if (rank > 4 || (rank == 4 && uint16_t(dims[3]) != dims[3])) break;
      representation_.rep32.rank = rank;
      representation_.rep32.kind = RepKind::kRep32;
      switch (rank) {
        case 4:
          representation_.rep32.dim3 = uint16_t(dims[3]);
          LLVM_FALLTHROUGH;
        case 3:
          representation_.rep32.dims[2] = dims[2];
          LLVM_FALLTHROUGH;
        case 2:
          representation_.rep32.dims[1] = dims[1];
          LLVM_FALLTHROUGH;
        case 1:
          representation_.rep32.dims[0] = dims[0];
          break;
        default:
          assert(0 && "unreachable");
      }
      return;
    }

    // If this dimension fits in 32 bits, then keep scanning.
    auto this_dim = dims[next_dim];
    if (uint32_t(this_dim) != this_dim) break;
    ++next_dim;
  }

  // Otherwise, nothing fits, use the most general representation.
  auto* elts = new size_t[rank];
  memcpy(elts, dims.data(), sizeof(size_t) * rank);
  representation_.rep_external.dims = elts;
  representation_.rep_external.rank = rank;
  representation_.rep_external.kind = RepKind::kRepExternal;
}

bool TensorShape::operator==(const TensorShape& other) const {
  // We assume that two identical shapes have the same representation kind.
  if (GetRepresentationKind() != other.GetRepresentationKind()) return false;
  if (!IsRepresentationExternal()) {
    // Both rep16 and rep32 have the same size and share the same memory, so
    // either representation is sufficient when comparing the block of memory.
    return memcmp(&representation_, &other.representation_,
                  sizeof(representation_)) == 0;
  }
  if (GetRank() != other.GetRank()) return false;
  return std::equal(representation_.rep_external.dims,
                    representation_.rep_external.dims + GetRank(),
                    other.representation_.rep_external.dims);
  return true;
}

bool TensorShape::operator!=(const TensorShape& other) const {
  return !(*this == other);
}

// Return the total number of elements in this TensorShape.  This is all of
// the dimensions multiplied together.
ssize_t TensorShape::GetNumElements() const {
  ssize_t result = 1;
  switch (GetRepresentationKind()) {
    case RepKind::kRep16:
      for (size_t i = 0, e = GetRank(); i != e; ++i)
        result *= representation_.rep16.dims[i];
      return result;

    case RepKind::kRep32:
      switch (GetRank()) {
        case 4:
          result = representation_.rep32.dim3;
          LLVM_FALLTHROUGH;
        case 3:
          result *= representation_.rep32.dims[2];
          LLVM_FALLTHROUGH;
        case 2:
          result *= representation_.rep32.dims[1];
          LLVM_FALLTHROUGH;
        case 1:
          result *= representation_.rep32.dims[0];
          return result;
        default:
          assert(0 && "unreachable");
          return result;
      }

    case RepKind::kRepExternal:
      for (size_t i = 0, e = GetRank(); i != e; ++i)
        result *= representation_.rep_external.dims[i];
      return result;
  }
}

void TensorShape::GetDimensions(MutableArrayRef<ssize_t> result) const {
  auto rank = GetRank();
  assert(rank == result.size() && "Incorrect rank");
  switch (GetRepresentationKind()) {
    case RepKind::kRep16:
      for (int i = 0, e = rank; i != e; ++i)
        result[i] = representation_.rep16.dims[i];
      return;

    case RepKind::kRep32:
      switch (rank) {
        case 4:
          result[3] = representation_.rep32.dim3;
          LLVM_FALLTHROUGH;
        case 3:
          result[2] = representation_.rep32.dims[2];
          LLVM_FALLTHROUGH;
        case 2:
          result[1] = representation_.rep32.dims[1];
          LLVM_FALLTHROUGH;
        case 1:
          result[0] = representation_.rep32.dims[0];
          return;
        default:
          assert(0 && "unreachable");
          return;
      }

    case RepKind::kRepExternal:
      memcpy(result.data(), representation_.rep_external.dims,
             sizeof(size_t) * rank);
      return;
  }
}

// Return all of the dimensions in this TensorShape in a way that is easy to
// process.
void TensorShape::GetDimensions(SmallVectorImpl<ssize_t>* result) const {
  result->resize(GetRank());
  GetDimensions(*result);
}

ssize_t TensorShape::GetDimensionSize(int dim_idx) const {
  assert(dim_idx < GetRank());
  switch (GetRepresentationKind()) {
    case RepKind::kRep16:
      return representation_.rep16.dims[dim_idx];

    case RepKind::kRep32:
      switch (dim_idx) {
        case 3:
          return representation_.rep32.dim3;
        case 2:
          return representation_.rep32.dims[2];
        case 1:
          return representation_.rep32.dims[1];
        case 0:
          return representation_.rep32.dims[0];
        default:
          assert(0 && "unreachable");
          return 0;
      }

    case RepKind::kRepExternal:
      return representation_.rep_external.dims[dim_idx];
  }
}

raw_ostream& operator<<(raw_ostream& os, const PartialTensorShape& value) {
  if (value.IsUnranked()) {
    return os << "Unknown rank";
  }

  os << '[';
  if (!value.GetShape()->empty()) {
    llvm::interleaveComma(value.GetShape().getValue(), os);
  }
  return os << ']';
}

PartialTensorShape::PartialTensorShape(Optional<ArrayRef<int64_t>> dims) {
  if (dims.hasValue()) {
    SmallVector<int64_t, 4> dims_vec{dims.getValue().begin(),
                                     dims.getValue().end()};
    dims_ = std::move(dims_vec);
  }
}

bool PartialTensorShape::IsUnranked() const {
  if (dims_.hasValue()) {
    return false;
  }
  return true;
}

Optional<ArrayRef<int64_t>> PartialTensorShape::GetShape() const {
  if (IsUnranked()) {
    return llvm::None;
  }
  return llvm::makeArrayRef(dims_.getValue());
}

bool PartialTensorShape::IsShapeKnown() const {
  if (IsUnranked()) {
    return false;
  }
  // TODO(ashwinm): This can be precomputed.
  return std::find_if(dims_->begin(), dims_->end(),
                      PartialTensorShape::IsUnknownDim) == dims_->end();
}

int PartialTensorShape::GetRank() const {
  if (IsUnranked()) {
    return PartialTensorShape::kUnknownDimSize;
  }
  return GetShape().getValue().size();
}

int64_t PartialTensorShape::GetDimensionSize(int dim_idx) const {
  assert(!IsUnranked() && "GetDim must be called on a ranked tensor shape");
  assert(dim_idx >= 0 && dim_idx < GetRank() &&
         "Index i must be in the range of [0, rank)");

  return (*dims_)[dim_idx];
}

Expected<TensorShape> PartialTensorShape::ToTensorShape() const {
  if (IsShapeKnown()) {
    return TensorShape(dims_.getValue());
  }

  if (IsUnranked()) {
    return MakeStringError("Unknown rank");
  }

  SmallVector<ssize_t, 4> unknown_dims;
  for (int i = 0; i < dims_->size(); i++) {
    if (IsUnknownDim(dims_.getValue()[i])) {
      unknown_dims.push_back(i);
    }
  }
  std::string str;
  llvm::raw_string_ostream os(str);
  os << "[";
  llvm::interleaveComma(unknown_dims, os);
  os << "]";
  return MakeStringError("Unknown dimensions at following indices = ", str);
}

template <size_t Rank>
raw_ostream& operator<<(raw_ostream& os, const FixedRankShape<Rank>& value) {
  os << '[';
  if (value.GetNumElements() > 0) {
    auto it = value.begin();
    os << *it;
    while (++it != value.end()) {
      os << ", " << *it;
    }
  }
  return os << ']';
}

template raw_ostream& operator<<(raw_ostream& os,
                                 const FixedRankShape<0>& value);
template raw_ostream& operator<<(raw_ostream& os,
                                 const FixedRankShape<1>& value);
template raw_ostream& operator<<(raw_ostream& os,
                                 const FixedRankShape<2>& value);
template raw_ostream& operator<<(raw_ostream& os,
                                 const FixedRankShape<3>& value);
template raw_ostream& operator<<(raw_ostream& os,
                                 const FixedRankShape<4>& value);

}  // namespace tfrt
