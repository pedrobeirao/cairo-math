/// @notice Finds the zero-based index of the first one in the binary representation of x.
/// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return msb The index of the most significant bit as an uint256.
func mostSignificantBit(x) -> (r):
    uint t;
    if ((t = (x >> 128)) > 0) { x = t; r += 128; }
    if ((t = (x >> 64)) > 0) { x = t; r += 64; }
    if ((t = (x >> 32)) > 0) { x = t; r += 32; }
    if ((t = (x >> 16)) > 0) { x = t; r += 16; }
    if ((t = (x >> 8)) > 0) { x = t; r += 8; }
    if ((t = (x >> 4)) > 0) { x = t; r += 4; }
    if ((t = (x >> 2)) > 0) { x = t; r += 2; }
    if ((t = (x >> 1)) > 0) { x = t; r += 1; }
end

### @notice Calculates the binary logarithm of x.
###
### @dev Based on the iterative approximation algorithm.
### https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
###
### Requirements:
### - x must be greater than zero.
###
### Caveats:
### - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
###
### @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
### @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
func log2(x) -> (result):
    require(x > 0);
    unchecked {
        ## This works because log2(x) = -log2(1/x).
        int256 sign;
        if x >= SCALE:
            sign = 1;
        else:
            sign = -1;
            ## Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            assembly {
                x := div(1000000000000000000000000000000000000, x)
            }

        ## Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        n = mostSignificantBit(Uint256(x / SCALE));

        ## The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
        ## because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
        result = int256(n) * SCALE;

        ## This is y = x * 2^(-n).
        y = x >> n;

        ## If y = 1, the fractional part is zero.
        if y == SCALE:
            return result * sign;


        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
            y = (y * y) / SCALE;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= 2 * SCALE) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result *= sign;
    }
}

/// @notice Calculates the natural logarithm of x.
///
/// @dev Based on the insight that ln(x) = log2(x) / log2(e).
///
/// Requirements:
/// - All from "log2".
///
/// Caveats:
/// - All from "log2".
/// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
///
/// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
/// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
function ln(int256 x) internal pure returns (int256 result) {
    // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
    // can return is 195205294292027477728.
    unchecked { result = (log2(x) * SCALE) / LOG2_E; }
}