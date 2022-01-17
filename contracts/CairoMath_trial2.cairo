# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.math import (signed_div_rem, sign, assert_not_equal)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_lt, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write

## @title CairoMath
## @author Pedro Beirao, adapting PRBMath Solidity library by Paul Razvan Berg
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
func exp2(x: felt) -> (result):
    let (res) = is_lt(x, -0x400000000000000000)
    if res == 1:
        return (z = 0) ## Underflow
    end

    result = 0x80000000000000000000000000000000
    let (res1) = assert_ge(x, 64)
    let (res2) = is_ge(result, 63 - (res1))
    if res2 == 1:
        return (result)

end