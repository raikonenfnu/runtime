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

//===- tfrt_base.td -------------------------------------------------------===//
//
// This file defines TFRT dialect and its types.
//
//===----------------------------------------------------------------------===//

#ifdef TFRT_BASE
#else
#define TFRT_BASE

include "mlir/IR/OpBase.td"

// Host Executor dialect.
def TFRT_Dialect : Dialect {
  let name = "tfrt";

  let description = [{
    The Host Executor dialect.

    This dialect contains common host operations.
  }];

  let cppNamespace = "::tfrt";
}

def TFRT_ChainType :
    Type<CPred<"$_self.isa<tfrt::ChainType>()">, "!tfrt.chain type">,
    BuildableType<"$_builder.getType<tfrt::ChainType>()">;

#endif  // TFRT_BASE
