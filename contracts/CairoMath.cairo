# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.default_dict import default_dict_finalize, default_dict_new
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.uint256 import Uint256

from starkware.cairo.common.math import assert_le, assert_lt, assert_nn, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write

## @title CairoMath
## @author Pedro Beirao
## @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
## trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
## a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
## are bound by the minimum and the maximum values permitted by the Solidity type int256.

@view
func power(base: felt, exponent: felt) -> (z: felt):
	if exponent == 0:
		return (z = 1)
	end

	if exponent == 1:
		return (z = base)
	end

	if base + exponent == base:
		return (z = 0)
	end

	let z = base
	return (z = z * base)
	end

@view
func exp2(x: felt) -> (result: felt):
	assert_le(x, 4611686018427387904) #2^62
	if res == 1:
		return (z = 0) ## Underflow
	end

	const result = 170141183460469231731687303715884105728 #2^127
	assert_nn(x-64)
	assert_nn(result-63 + x)
	return (result)
	end

#@view
#func log(x: felt, base: felt):
#	let count = -1
#	assert_lt(x, 0)
#	assert_ne(x,base)
#	count += 1
#	if x == 0:
#		return count
#	end

@view
func log2 (x) -> ():
#**
# * Return index of most significant non-zero bit in given non-zero 256-bit
# * unsigned integer value.
# *
# * @param x value to get index of most significant non-zero bit in
# * @return index of most significant non-zero bit in given number
# */
      assert_lt(x,0)
      msb = 0
      xc = x
      if xc >= 0x10000000000000000: 
      		xc >>= 64 
      		msb += 64
      if xc >= 0x100000000: 
      		xc >>= 32 
      		msb += 32
      if xc >= 0x10000:
      		xc >>= 16
      		msb += 16
      if xc >= 0x100:
      		xc >>= 8
      		msb += 8
      if xc >= 0x10:
      		xc >>= 4
      		msb += 4
      if xc >= 0x4:
      		xc >>= 2
      		msb += 2
      if xc >= 0x2:
      		msb += 1 

      result = msb - 64 << 64;
      ux = Uint256(x << uint256 (127 - msb))
#      for bit = 0x8000000000000000; bit > 0; bit >>= 1) {
#        ux *= ux;
#        uint256 b = ux >> 255;
#        ux >>= 127 + b;
#        result += bit * int256 (b);
#      }
#
#      return int128 (result);
#    }
#  }

@view
func ln (x) -> ():
    assert_ge(x,0)
    return (log2 (x)) * (0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128)
end
