%lang starknet
%builtins pedersen range_check

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.math import assert_le, assert_nn_le, unsigned_div_rem, assert_not_zero
from starkware.starknet.common.syscalls import storage_read, storage_write
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)

## @title CairoMath
## @author Pedro Beirao, adapting PRBMath Solidity library by Paul Razvan Berg
## @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
## trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
## a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
## are bound by the minimum and the maximum values permitted by the Solidity type int256.


## @dev Common mathematical functions used in CairoMathSD59x18 and CairoMathUD60x18. Note that this shared library
## does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
## representation. When it does not, it is explicitly mentioned in the NatSpec documentation.

#############################################
##                 STORAGE                 ##
#############################################

## @dev How many trailing decimals can be represented.
const SCALE = 1e18

## @dev Largest power of two divisor of SCALE.
const SCALE_LPOTD = 262144

## @dev SCALE inverted mod 2^256.
const SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661.508869554232690281

### @dev log2(e) as a signed 59.18-decimal fixed-point number.
const LOG2_E = 1.442695040888963407

### @dev Half the SCALE number.
const HALF_SCALE = 5e17

### @dev The maximum value a signed 59.18-decimal fixed-point number can have.
const MAX = 57896044618658097711785492504343953926634992332820282019728.792003956564819967

### @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
const MAX_WHOLE = 57896044618658097711785492504343953926634992332820282019728.000000000000000000

### @dev The minimum value a signed 59.18-decimal fixed-point number can have.
const MIN = -57896044618658097711785492504343953926634992332820282019728_792003956564819968

### @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
const MIN_WHOLE = -57896044618658097711785492504343953926634992332820282019728.000000000000000000

### @dev How many trailing decimals can be represented.
const SCALE = 1e18


#############################################
##                 FUNCTIONS                 ##
#############################################

## @notice Calculates the binary exponent of x using the binary fraction method.
## @dev Has to use 192.64-bit fixed-point numbers.
## See https://ethereum.stackexchange.com/a/96594/24693.
## @param x The exponent as an unsigned 192.64-bit fixed-point number.
## @return result The result as an unsigned 60.18-decimal fixed-point number.

@view
func exp2(x: felt) -> (sum: felt):
    ## Start from 0.5 in the 192.64-bit fixed-point format.
    result = 0x800000000000000000000000000000000000000000000000

    ## Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
    ## because the initial result is 2^191 and all magic factors are less than 2^65.
    if (x & 0x8000000000000000) > 0:
        result = (result * 0x16A09E667F3BCC909) >> 64

    if (x & 0x4000000000000000) > 0:
        result = (result * 0x1306FE0A31B7152DF) >> 64

    if (x & 0x2000000000000000) > 0:
        result = (result * 0x1172B83C7D517ADCE) >> 64

    if (x & 0x1000000000000000) > 0:
        result = (result * 0x10B5586CF9890F62A) >> 64

    if x & 0x800000000000000 > 0:
        result = (result * 0x1059B0D31585743AE) >> 64

    if x & 0x400000000000000 > 0:
        result = (result * 0x102C9A3E778060EE7) >> 64

    if x & 0x200000000000000 > 0:
        result = (result * 0x10163DA9FB33356D8) >> 64

    if x & 0x100000000000000 > 0:
        result = (result * 0x100B1AFA5ABCBED61) >> 64

    if x & 0x80000000000000 > 0:
        result = (result * 0x10058C86DA1C09EA2) >> 64

    if x & 0x40000000000000 > 0:
        result = (result * 0x1002C605E2E8CEC50) >> 64

    if x & 0x20000000000000 > 0:
        result = (result * 0x100162F3904051FA1) >> 64

    if x & 0x10000000000000 > 0:
        result = (result * 0x1000B175EFFDC76BA) >> 64

    if x & 0x8000000000000 > 0:
        result = (result * 0x100058BA01FB9F96D) >> 64

    if x & 0x4000000000000 > 0:
        result = (result * 0x10002C5CC37DA9492) >> 64

    if x & 0x2000000000000 > 0:
        result = (result * 0x1000162E525EE0547) >> 64

    if x & 0x1000000000000 > 0:
        result = (result * 0x10000B17255775C04) >> 64

    if x & 0x800000000000 > 0:
        result = (result * 0x1000058B91B5BC9AE) >> 64

    if x & 0x400000000000 > 0:
        result = (result * 0x100002C5C89D5EC6D) >> 64

    if x & 0x200000000000 > 0:
        result = (result * 0x10000162E43F4F831) >> 64

    if x & 0x100000000000 > 0:
        result = (result * 0x100000B1721BCFC9A) >> 64

    if x & 0x80000000000 > 0:
        result = (result * 0x10000058B90CF1E6E) >> 64

    if x & 0x40000000000 > 0:
        result = (result * 0x1000002C5C863B73F) >> 64

    if x & 0x20000000000 > 0:
        result = (result * 0x100000162E430E5A2) >> 64

    if x & 0x10000000000 > 0:
        result = (result * 0x1000000B172183551) >> 64

    if x & 0x8000000000 > 0:
        result = (result * 0x100000058B90C0B49) >> 64

    if x & 0x4000000000 > 0:
        result = (result * 0x10000002C5C8601CC) >> 64

    if x & 0x2000000000 > 0:
        result = (result * 0x1000000162E42FFF0) >> 64

    if x & 0x1000000000 > 0:
        result = (result * 0x10000000B17217FBB) >> 64

    if x & 0x800000000 > 0:
        result = (result * 0x1000000058B90BFCE) >> 64

    if x & 0x400000000 > 0:
        result = (result * 0x100000002C5C85FE3) >> 64

    if x & 0x200000000 > 0:
        result = (result * 0x10000000162E42FF1) >> 64

    if x & 0x100000000 > 0:
        result = (result * 0x100000000B17217F8) >> 64

    if x & 0x80000000 > 0:
        result = (result * 0x10000000058B90BFC) >> 64

    if x & 0x40000000 > 0:
        result = (result * 0x1000000002C5C85FE) >> 64

    if x & 0x20000000 > 0:
        result = (result * 0x100000000162E42FF) >> 64

    if x & 0x10000000 > 0:
        result = (result * 0x1000000000B17217F) >> 64

    if x & 0x8000000 > 0:
        result = (result * 0x100000000058B90C0) >> 64

    if x & 0x4000000 > 0:
        result = (result * 0x10000000002C5C860) >> 64

    if x & 0x2000000 > 0:
        result = (result * 0x1000000000162E430) >> 64

    if x & 0x1000000 > 0:
        result = (result * 0x10000000000B17218) >> 64

    if x & 0x800000 > 0:
        result = (result * 0x1000000000058B90C) >> 64

    if x & 0x400000 > 0:
        result = (result * 0x100000000002C5C86) >> 64

    if x & 0x200000 > 0:
        result = (result * 0x10000000000162E43) >> 64

    if x & 0x100000 > 0:
        result = (result * 0x100000000000B1721) >> 64

    if x & 0x80000 > 0:
        result = (result * 0x10000000000058B91) >> 64

    if x & 0x40000 > 0:
        result = (result * 0x1000000000002C5C8) >> 64

    if x & 0x20000 > 0:
        result = (result * 0x100000000000162E4) >> 64

    if x & 0x10000 > 0:
        result = (result * 0x1000000000000B172) >> 64

    if x & 0x8000 > 0:
        result = (result * 0x100000000000058B9) >> 64

    if x & 0x4000 > 0:
        result = (result * 0x10000000000002C5D) >> 64

    if x & 0x2000 > 0:
        result = (result * 0x1000000000000162E) >> 64

    if x & 0x1000 > 0:
        result = (result * 0x10000000000000B17) >> 64

    if x & 0x800 > 0:
        result = (result * 0x1000000000000058C) >> 64

    if x & 0x400 > 0:
        result = (result * 0x100000000000002C6) >> 64

    if x & 0x200 > 0:
        result = (result * 0x10000000000000163) >> 64

    if x & 0x100 > 0:
        result = (result * 0x100000000000000B1) >> 64

    if x & 0x80 > 0:
        result = (result * 0x10000000000000059) >> 64

    if x & 0x40 > 0:
        result = (result * 0x1000000000000002C) >> 64

    if x & 0x20 > 0:
        result = (result * 0x10000000000000016) >> 64

    if x & 0x10 > 0:
        result = (result * 0x1000000000000000B) >> 64

    if x & 0x8 > 0:
        result = (result * 0x10000000000000006) >> 64

    if x & 0x4 > 0:
        result = (result * 0x10000000000000003) >> 64

    if x & 0x2 > 0:
        result = (result * 0x10000000000000001) >> 64

    if x & 0x1 > 0:
        result = (result * 0x10000000000000001) >> 64


    ## We're doing two things at the same time:
    ##
    ##   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
    ##      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
    ##      rather than 192.
    ##   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
    ##
    ## This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
    result *= SCALE
    result >>= (191 - (x >> 64))
    return(result)
end

@view
func sqrt(x: felt) -> (result: felt):
    if x == 0:
        return 0

    ## Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
    xAux = x
    result = 1
    if xAux >= 0x100000000000000000000000000000000:
        xAux >>= 128
        result <<= 64

    if xAux >= 0x10000000000000000:
        xAux >>= 64
        result <<= 32

    if xAux >= 0x100000000:
        xAux >>= 32
        result <<= 16

    if xAux >= 0x10000:
        xAux >>= 16
        result <<= 8

    if xAux >= 0x100:
        xAux >>= 8
        result <<= 4

    if xAux >= 0x10:
        xAux >>= 4
        result <<= 2

    if xAux >= 0x8:
        result <<= 1

    ## The operations can never overflow because the result is max 2^127 when it enters this block.

    result = (result + x / result) >> 1
    result = (result + x / result) >> 1
    result = (result + x / result) >> 1
    result = (result + x / result) >> 1
    result = (result + x / result) >> 1
    result = (result + x / result) >> 1
    result = (result + x / result) >> 1 ## Seven iterations should be enough
    roundedDownResult = x / result
    return(roundedDownResult)
end

### @notice Calculate the absolute value of x.
###
### @dev Requirements:
### - x must be greater than MIN_SD59x18.
###
### @param x The number to calculate the absolute value for.
### @param result The absolute value of x.

@view
func abs(x: felt) -> (result: felt):
    result(x < 0 ? -x : x)
end

### @notice Calculates the arithmetic average of x and y, rounding down.
### @param x The first operand as a signed 59.18-decimal fixed-point number.
### @param y The second operand as a signed 59.18-decimal fixed-point number.
### @return result The arithmetic average as a signed 59.18-decimal fixed-point number.

@view
func avg(x: felt, y: felt) -> (result: felt):
    ## The operations can never overflow.
    sum = (x >> 1) + (y >> 1)
    if sum < 0:
        ## If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
        ## right rounds down to infinity.
        result(add(sum, and(or(x, y), 1)))

    else:
        ## If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
        ## remainder gets truncated twice.
        result(sum + (x & y & 1))
end

### @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
###
### @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
### See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
###
### Requirements:
### - x must be less than or equal to MAX_WHOLE_SD59x18.
###
### @param x The signed 59.18-decimal fixed-point number to ceil.
### @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
@view
func ceil(x: felt) -> (result: felt):
    remainder = x % SCALE
    if remainder == 0:
        result(x)
    else:
        result(x - remainder)
#        if x > 0:
#            result += SCALE
end

### @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
### @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
@view
func e() -> (result: felt):
    result = 2.718281828459045235
end

### @notice Calculates the natural exponent of x.
###
### @dev Based on the insight that e^x = 2^(x * log2(e)).
###
### Requirements:
### - All from "log2".
### - x must be less than 133.084258667509499441.
###
### Caveats:
### - All from "exp2".
### - For any x less than -41.446531673892822322, the result is zero.
###
### @param x The exponent as a signed 59.18-decimal fixed-point number.
### @return result The result as a signed 59.18-decimal fixed-point number.
@view
func exp(x: felt) -> (result: felt):
    ## Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
    if x < -41.446531673892822322:
        return(0)

    ## Do the fixed-point multiplication inline to save gas.
    doubleScaleProduct = x * LOG2_E
    result(exp2((doubleScaleProduct + HALF_SCALE) / SCALE))
end

### @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
###
### @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
### See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
###
### Requirements:
### - x must be greater than or equal to MIN_WHOLE_SD59x18.
###
### @param x The signed 59.18-decimal fixed-point number to floor.
### @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
@view
func floor(x: felt) -> (result: felt):
    remainder = x % SCALE
    if remainder == 0:
        result = x
            ## Solidity uses C fmod style, which returns a modulus with the same sign as x.
            result(x - remainder)
#            if x < 0:
#                result -= SCALE
end

### @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
### of the radix point for negative numbers.
### @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
### @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
### @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
@view
func frac(x: felt) -> (result: felt):
        result = x % SCALE
end

### @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
###
### @dev Requirements:
### - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
### - x must be less than or equal to MAX_SD59x18 divided by SCALE.
###
### @param x The basic integer to convert.
### @param result The same number in signed 59.18-decimal fixed-point representation.
@view
func fromInt(x: felt) -> (result: felt):
    result(x * SCALE)
end

### @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
###
### @dev Requirements:
### - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
### - x must be less than or equal to MAX_SD59x18 divided by SCALE.
###
### @param x The basic integer to convert.
### @param result The same number in signed 59.18-decimal fixed-point representation.
@view
func fromInt(x: felt) -> (result: felt):
    result(x * SCALE)
end

### @notice Calculates 1 / x, rounding toward zero.
###
### @dev Requirements:
### - x cannot be zero.
###
### @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
### @return result The inverse as a signed 59.18-decimal fixed-point number.
@view
func inv(x: felt) -> (result: felt):
        ## 1e36 is SCALE * SCALE.
        result = 1e36 / x
end

### @notice Calculates the natural logarithm of x.
###
### @dev Based on the insight that ln(x) = log2(x) / log2(e).
###
### Requirements:
### - All from "log2".
###
### Caveats:
### - All from "log2".
### - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
###
### @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
### @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
@view
func ln(x: felt) -> (result: felt):
    ## Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
    ## can return is 195205294292027477728.
    result((log2_bis(x) * SCALE) / LOG2_E)
end

    ### @notice Calculates the common logarithm of x.
    ###
    ### @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    ### logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ###
    ### Requirements:
    ### - All from "log2".
    ###
    ### Caveats:
    ### - All from "log2".
    ###
    ### @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    ### @return result The common logarithm as a signed 59.18-decimal fixed-point number.
@view
func log10(x: felt) -> (result: felt):
    ## Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
    ## prettier-ignore
    result((log2(x) * SCALE) / 3.321928094887362347)
end

@view
func log2(x: felt) -> (result: felt):
    if x >= SCALE:
        sign = 1
    else:
        sign = -1

        ## Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        n = mostSignificantBit(x / SCALE)

        ## The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
        ## because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
        result = Uint256(n) * SCALE

        ## This is y = x * 2^(-n).
        y = x >> n

        ## If y = 1, the fractional part is zero.
        if y == SCALE:
            return(result * sign)

        ## Calculate the fractional part via the iterative approximation.
        ## The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for delta = Uint256(HALF_SCALE) delta > 0 delta >>= 1:
            y = (y * y) / SCALE

            ## Is y^2 > 2 and so in the range [2,4)?
#            if y >= 2 * SCALE:
                ## Add the 2^(-m) factor to the logarithm.
#                result += delta

                ## Corresponds to z/2 on Wikipedia.
                y >>= 1
#        result *= sign
end

### @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
### fixed-point number.
###
### @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
### always 1e18.
###
### Requirements:
### - All from "PRBMath.mulDivFixedPoint".
### - None of the inputs can be MIN_SD59x18
### - The result must fit within MAX_SD59x18.
###
### Caveats:
### - The body is purposely left uncommented see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
###
### @param x The multiplicand as a signed 59.18-decimal fixed-point number.
### @param y The multiplier as a signed 59.18-decimal fixed-point number.
### @return result The product as a signed 59.18-decimal fixed-point number.
@view
func mul(x: felt, y: felt) -> (result: felt):

    ax = x < 0 ? Uint256(-x) : Uint256(x)
    ay = y < 0 ? Uint256(-y) : Uint256(y)

    rAbs = mulDivFixedPoint(ax, ay)

    result(sx ^ sy == 1 ? -Uint256(rAbs) : Uint256(rAbs))
end

### @notice Returns PI as a signed 59.18-decimal fixed-point number.
@view
func pi() -> (result: felt):
    result(3.141592653589793238)
end

### @notice Raises x to the power of y.
###
### @dev Based on the insight that x^y = 2^(log2(x) * y).
###
### Requirements:
### - All from "exp2", "log2" and "mul".
### - z cannot be zero.
###
### Caveats:
### - All from "exp2", "log2" and "mul".
### - Assumes 0^0 is 1.
###
### @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
### @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
### @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
@view
func pow(x: felt, y: felt) -> (result: felt):
    if x == 0:
        result = y == 0 ? SCALE : Uint256(0)
    else:
        result = exp2(mul(log2(x), y))
end

### @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
### famous algorithm "exponentiation by squaring".
###
### @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
###
### Requirements:
### - All from "abs" and "PRBMath.mulDivFixedPoint".
### - The result must fit within MAX_SD59x18.
###
### Caveats:
### - All from "PRBMath.mulDivFixedPoint".
### - Assumes 0^0 is 1.
###
### @param x The base as a signed 59.18-decimal fixed-point number.
### @param y The exponent as an uint256.
### @return result The result as a signed 59.18-decimal fixed-point number.
@view
func powu(x: felt, y: felt) -> (result: felt):
    xAbs = (abs(x))

    ## Calculate the first iteration of the loop in advance.
    rAbs = y & 1 > 0 ? xAbs : Uint256(SCALE)

    ## Equivalent to "for(y /= 2 y > 0 y /= 2)" but faster.
    yAux = y
    for yAux >>= 1 yAux > 0 yAux >>= 1:
        xAbs = mulDivFixedPoint(xAbs, xAbs)

        ## Equivalent to "y % 2 == 1" but faster.
        if yAux & 1 > 0:
            rAbs = mulDivFixedPoint(rAbs, xAbs)

    ## Is the base negative and the exponent an odd number?
    isNegative = x < 0 && y & 1 == 1
    result(isNegative ? -int256(rAbs) : int256(rAbs))
end

### @notice Returns 1 as a signed 59.18-decimal fixed-point number.
@view
func scale() -> (result: felt):
    result = SCALE
end


### @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
### @param x The signed 59.18-decimal fixed-point number to convert.
### @return result The same number in basic integer form.
@view
func toInt(x: felt) -> (result: felt):
        result(x / SCALE)
end
