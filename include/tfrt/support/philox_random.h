/*
 * Copyright 2020 The TensorFlow Runtime Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//===- philox_random.h ------------------------------------------*- C++ -*-===//
//
// This file implements the Philox algorithm to generate random numbers in
// parallel.
// Salmon et al. SC 2011. Parallel random numbers: as easy as 1, 2, 3.
//   http://www.thesalmons.org/john/random123/papers/random123sc11.pdf
//
//===----------------------------------------------------------------------===//

#ifndef TFRT_SUPPORT_PHILOX_RANDOM_H_
#define TFRT_SUPPORT_PHILOX_RANDOM_H_

#include <math.h>
#include <stdlib.h>

#include <array>

#include "tfrt/support/forward_decls.h"

namespace tfrt {
namespace random {

// This class implements the philox_4x32_10 algorithm. There are multiple
// variants of this algorithm, we picked the 4x32_10 version that is most suited
// for our applications.
class PhiloxRandom {
 public:
  static const int kCounterSize = 4;
  using CounterType = std::array<uint32_t, kCounterSize>;
  // The type for the 64-bit key stored in the form of two 32-bit uint
  // that are used in the diffusion process.
  using KeyType = std::array<uint32_t, 2>;

  PhiloxRandom(uint64_t seed_lo, uint64_t seed_hi) {
    key_[0] = static_cast<uint32_t>(seed_lo);
    key_[1] = static_cast<uint32_t>(seed_lo >> 32);
    counter_[2] = static_cast<uint32_t>(seed_hi);
    counter_[3] = static_cast<uint32_t>(seed_hi >> 32);
  }

  // Returns a 32-bit random bits as uint32_t. Internally the Philox algorithm
  // always computes 128-bit random bits at a time. These 128 bits will returned
  // as four separate uint32_t values.
  uint32_t operator()() {
    if (next_result_index_ == kCounterSize) {
      cached_results_ = computeRandomBits();
      next_result_index_ = 0;
    }
    return cached_results_[next_result_index_++];
  }

 private:
  // Uses the same constants as recommended by the original paper.
  static constexpr uint32_t kPhiloxW32A = 0x9E3779B9;
  static constexpr uint32_t kPhiloxW32B = 0xBB67AE85;
  static constexpr uint32_t kPhiloxM4x32A = 0xD2511F53;
  static constexpr uint32_t kPhiloxM4x32B = 0xCD9E8D57;

  // Computes a group of four random numbers using the Philox algorithm.
  CounterType computeRandomBits() {
    CounterType counter = counter_;
    KeyType key = key_;

    // Run the single rounds for ten times. Manually unrolling the loop
    // for better performance.
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);
    RaiseKey(&key);
    counter = ComputeSingleRound(counter, key);

    SkipOne();

    return counter;
  }

  // Helper function to skip the next sample of 128-bits in the current stream.
  void SkipOne() {
    if (++counter_[0] == 0) {
      if (++counter_[1] == 0) {
        if (++counter_[2] == 0) {
          ++counter_[3];
        }
      }
    }
  }

  void RaiseKey(KeyType* key) {
    (*key)[0] += kPhiloxW32A;
    (*key)[1] += kPhiloxW32B;
  }

  // Helper function to return the lower and higher 32-bits from two 32-bit
  // integer multiplications.
  static void MultiplyHighLow(uint32_t a, uint32_t b, uint32_t* result_low,
                              uint32_t* result_high) {
    const uint64_t product = static_cast<uint64_t>(a) * b;
    *result_low = static_cast<uint32_t>(product);
    *result_high = static_cast<uint32_t>(product >> 32);
  }

  // Helper function for a single round of the underlying Philox algorithm.
  static CounterType ComputeSingleRound(const CounterType& counter,
                                        const KeyType& key) {
    uint32_t lo0;
    uint32_t hi0;
    MultiplyHighLow(kPhiloxM4x32A, counter[0], &lo0, &hi0);

    uint32_t lo1;
    uint32_t hi1;
    MultiplyHighLow(kPhiloxM4x32B, counter[2], &lo1, &hi1);

    CounterType next_counter;
    next_counter[0] = hi1 ^ counter[1] ^ key[0];
    next_counter[1] = lo1;
    next_counter[2] = hi0 ^ counter[3] ^ key[1];
    next_counter[3] = lo0;
    return next_counter;
  }

  // States of the Philox random number generator algorithm.
  CounterType counter_{0, 0, 0, 0};
  KeyType key_{0, 0};
  // The 128-bit random bits generated by the most recent invocation of the
  // Philox algorithm.
  CounterType cached_results_;
  // The index of the next 32-bit integer in the `cached_results_` that should
  // be returned to the caller.
  int next_result_index_ = kCounterSize;
};

}  // namespace random
}  // namespace tfrt

#endif  // TFRT_SUPPORT_PHILOX_RANDOM_H_
