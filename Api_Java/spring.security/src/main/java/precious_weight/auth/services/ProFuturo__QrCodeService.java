package precious_weight.auth.services;

import org.springframework.stereotype.Service;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import javax.imageio.ImageIO;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.List;

// Reference: https://www.thonky.com/qr-code-tutorial/introduction
//Error code explained below:
 /*
          Explanation of theory from https://www.thonky.com/qr-code-tutorial/

        //Polynomial long division
        /**
           Overall, the steps of polynomial long division are:

              Find the appropriate term to multiply the divisor by. The result of the multiplication should have the same first term as the the dividend (in the first multiplication step) or remainder (in all subsequent multiplication steps).
              Subtract the result from the dividend (in the first multiplication step) or remainder (in all subsequent multiplication steps).
              Repeat steps 1 and 2 until it is no longer possible to multiply by an integer, or in other words, it would be necessary to multiply by a fraction. The number at the bottom of the tableau is the remainder.

           The polynomial long division necessary for Reed-Solomon Error Correction is simpler in some ways than this example, because it will not be necessary to deal with the exponents of the polynomial terms.

        // Step 3: Understand The Galois Field
        // To generate error correction codewords, this process uses a method called Reed-Solomon Error correction
        // Along with polynomial long division, this method uses a Galois field (256), which is essentially a restricted set of numbers, as well as some mathematical operations that create numbers that are still in that set.
        //  The numbers in GF(256) will all be in the range of 0 through 255 (inclusive).
        /**
          In the Galois Field, negative numbers have the same value as positive numbers, so -n = n.
          This means that addition and subtraction within the Galois Field are the same thing.
          Addition and subtraction in the Galois Field are performed by doing the addition or subtraction as normal, but then performing the modulo operation.
          And since we are using bit-wise modulo 2 arithmetic (as mentioned in the QR code specification), this is the same as performing the XOR operation.
          1 + 1 = 2. 2 % 2 = 0 -> The same of: 1 XOR(+ or -) 1 = 0
          0 + 1 = 1. 1 % 2 = 1 -> 0 XOR(^) 1 = 1

        //Step 5: Generate Powers of 2 using Byte-Wise Modulo 100011101
        /**
          All of the numbers in GF(256) can be represented as a power of 2.
          Specifically, all numbers in GF(256) can be represented as 2n, where 0 <= n <= 255.
          2 power 8 would seem to be too big for the Galois Field since it is equal to 256.
          The QR code specification says to use byte-wise modulo 100011101 arithmetic
          (where 100011101 is a binary number that is equivalent to 285 in decimal).
          This means that when a number is 256 or larger, it should be XORed with 285.
          This leads to unexpected values for 2 power 8 and larger.
          28 = 256. 256 > 255. 256 ^(XORed) 285 = 29
          When continuing on to 2 power 9, do not take its usual value of 512 and XOR with 285
          (which would result in too large a number anyway). Do it: 2 power 9 = 2 power 8 * 2.
          2 power 9 = 2 power 8 * 2 -> 29 (equivalent to 256 ^(XORed) 285) * 2 = 58
          Continue using the previous power of 2 to create the next powers of 2:
          2 power 10 = 2 power 9 * 2 = 58 * 2 = 116
          2 power11 = 2 power 10 * 2 = 116 * 2 = 232
          Whenever a value greater than or equal to 256 is obtained, once again XOR with 285:
          2 power 12 = 2 power 11 * 2 = 232 * 2 = 464. 464 >255 -> 464 ^ 285 = 205
          In general, the values are always equal to 2 times the previous power, and if that value is 256 or greater, it is XORed with 285.


        //Step 6: Understand Multiplication with Logs and Antilogs
        /**
          Because all of the values can be represented with 2n as explained above,
          it is possible to logs and antilogs to simplify multiplication in GF(256).
          one can multiply two numbers p and q with the following operation: b power (logb p + logb q)
          In this case, base 2 is in use, so the above operation becomes 2 power (log2 p + log2 q)
          The log2 x operation tells us how many times to multiply 2 to get an answer of x.
          In other words, it determines n where 2 power n = x. n = log2 p + log2 q
          This provides a shortcut for multiplying numbers in GF(256): 2 pow 2 * 2 pow 8 = 2 pow (2 + 8) = 2 pow 10
          And by this, we can discover all values of numbers in GF(256), based on Bitwise Modulo rule


        //Step 7: Understanding The Generator Polynomial
        /**
          As mentioned earlier, error correction coding uses polynomial long division.
          To do that, two polynomials are needed. The first polynomial to use is called
          the message polynomial.Uses the data codewords from the data encoding step as
          its coefficients.
          If the data codewords, converted to integers, were 25, 218, and 35,
          message polynomial would be 25x2 + 218x + 35.
          The message polynomial will be divided by a GeneratorPolynomial.
          The generator polynomial is a polynomial that is created by multiplying
          (x - ɑ0) ... (x - ɑn-1) where n is the number of error correction codewords
          that must be generated. (alpha) is equal to 2.
          So, need a function to generate dividend polynomial from a block in alpha notation
          Need a function to generate divisorpolynomial to divide based in value of error code per block
          NeededPolynomial = Dividend / Divisor;
          ****When we multiply two alpha values, normally we add the two exponents together.
          But if the result is bigger than 255, we have a problem.
          To prevent that we put the resulting exponent through the following formula:
                        (exponent % 256) + floor(exponent / 256)
          ****When adding terms in base of X during the creation of a generator polynomial,
          you must always XOR the integers rather than adding them.
         */

@Service
public class ProFuturo__QrCodeService {
    private final boolean debug = false;
    private final int CorrectionLevel = 2; //(Q by default)
    private int QrCodeLevel = -1;
    private int QrCodeSize = -1;

    private final int[][] BYTE_MODE_CAPACITY = {{17, 14, 11, 7}, {32, 26, 20, 14}, {53, 42, 32, 24}, {78, 62, 46, 34}, {106, 84, 60, 44}, {134, 106, 74, 58}, {154, 122, 86, 64}, {192, 152, 108, 84}, {230, 180, 130, 98}, {271, 213, 151, 119}, {321, 251, 177, 137}, {367, 287, 203, 155}, {425, 331, 241, 177}, {458, 362, 258, 194}, {520, 412, 292, 220}, {586, 450, 322, 250}, {644, 504, 364, 280}, {718, 560, 394, 310}, {792, 624, 442, 338}, {858, 666, 482, 382}, {929, 711, 509, 403}, {1003, 779, 565, 439}, {1091, 857, 611, 461}, {1171, 911, 661, 511}, {1273, 997, 715, 535}, {1367, 1059, 751, 593}, {1465, 1125, 805, 625}, {1528, 1190, 868, 658}, {1628, 1264, 908, 698}, {1732, 1370, 982, 742}, {1840, 1452, 1030, 790}, {1952, 1538, 1112, 842}, {2068, 1628, 1168, 898}, {2188, 1722, 1228, 958}, {2303, 1809, 1283, 983}, {2431, 1911, 1351, 1051}, {2563, 1989, 1423, 1093}, {2699, 2099, 1499, 1139}, {2809, 2213, 1579, 1219}, {2953, 2331, 1663, 1273}};
    private final int[][] Total_Codewords = {{19, 16, 13, 9}, {34, 28, 22, 16}, {55, 44, 34, 26}, {80, 64, 48, 36}, {108, 86, 62, 46}, {136, 108, 76, 60}, {156, 124, 88, 66}, {194, 154, 110, 86}, {232, 182, 132, 100}, {274, 216, 154, 122}, {324, 254, 180, 140}, {370, 290, 206, 158}, {428, 334, 244, 180}, {461, 365, 261, 197}, {523, 415, 295, 223}, {589, 453, 325, 253}, {647, 507, 367, 283}, {721, 563, 397, 313}, {795, 627, 445, 341}, {861, 669, 485, 385}, {932, 714, 512, 406}, {1006, 782, 568, 442}, {1094, 860, 614, 464}, {1174, 914, 664, 514}, {1276, 1000, 718, 538}, {1370, 1062, 754, 596}, {1468, 1128, 808, 628}, {1531, 1193, 871, 661}, {1631, 1267, 911, 701}, {1735, 1373, 985, 745}, {1843, 1455, 1033, 793}, {1955, 1541, 1115, 845}, {2071, 1631, 1171, 901}, {2191, 1725, 1231, 961}, {2306, 1812, 1286, 986}, {2434, 1914, 1354, 1054}, {2566, 1992, 1426, 1096}, {2702, 2102, 1502, 1142}, {2812, 2216, 1582, 1222}, {2956, 2334, 1666, 1276}};
    private final int[][] EC_Codewords_Per_Block = {{7, 10, 13, 17}, {10, 16, 22, 28}, {15, 26, 18, 22}, {20, 18, 26, 16}, {26, 24, 18, 22}, {18, 16, 24, 28}, {20, 18, 18, 26}, {24, 22, 22, 26}, {30, 22, 20, 24}, {18, 26, 24, 28}, {20, 30, 28, 24}, {24, 22, 26, 28}, {26, 22, 24, 22}, {30, 24, 20, 24}, {22, 24, 30, 24}, {24, 28, 24, 30}, {28, 28, 28, 28}, {30, 26, 28, 28}, {28, 26, 26, 26}, {28, 26, 30, 28}, {28, 26, 28, 30}, {28, 28, 30, 24}, {30, 28, 30, 30}, {30, 28, 30, 30}, {26, 28, 30, 30}, {28, 28, 28, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}, {30, 28, 30, 30}};
    private final int[][] Number_DataBlocks_Group1 = {{1, 1, 1, 1}, {1, 1, 1, 1}, {1, 1, 2, 2}, {1, 2, 2, 4}, {1, 2, 2, 2}, {2, 4, 4, 4}, {2, 4, 2, 4}, {2, 2, 4, 4}, {2, 3, 4, 4}, {2, 4, 6, 6}, {4, 1, 4, 3}, {2, 6, 4, 7}, {4, 8, 8, 12}, {3, 4, 11, 11}, {5, 5, 5, 11}, {5, 7, 15, 3}, {1, 10, 1, 2}, {5, 9, 17, 2}, {3, 3, 17, 9}, {3, 3, 15, 15}, {4, 17, 17, 19}, {2, 17, 7, 34}, {4, 4, 11, 16}, {6, 6, 11, 30}, {8, 8, 7, 22}, {10, 19, 28, 33}, {8, 22, 8, 12}, {3, 3, 4, 11}, {7, 21, 1, 19}, {5, 19, 15, 23}, {13, 2, 42, 23}, {17, 10, 10, 19}, {17, 14, 29, 11}, {13, 14, 44, 59}, {12, 12, 39, 22}, {6, 6, 46, 2}, {17, 29, 49, 24}, {4, 13, 48, 42}, {20, 40, 43, 10}, {19, 18, 34, 20}};
    private final int[][] Number_Data_Codewords_In_Blocks_Group1 = {{19, 16, 13, 9}, {34, 28, 22, 16}, {55, 44, 17, 13}, {80, 32, 24, 9}, {108, 43, 15, 11}, {68, 27, 19, 15}, {78, 31, 14, 13}, {97, 38, 18, 14}, {116, 36, 16, 12}, {68, 43, 19, 15}, {81, 50, 22, 12}, {92, 36, 20, 14}, {107, 37, 20, 11}, {115, 40, 16, 12}, {87, 41, 24, 12}, {98, 45, 19, 15}, {107, 46, 22, 14}, {120, 43, 22, 14}, {113, 44, 21, 13}, {107, 41, 24, 15}, {116, 42, 22, 16}, {111, 46, 24, 13}, {121, 47, 24, 15}, {117, 45, 24, 16}, {106, 47, 24, 15}, {114, 46, 22, 16}, {122, 45, 23, 15}, {117, 45, 24, 15}, {116, 45, 23, 15}, {115, 47, 24, 15}, {115, 46, 24, 15}, {115, 46, 24, 15}, {115, 46, 24, 15}, {115, 46, 24, 16}, {121, 47, 24, 15}, {121, 47, 24, 15}, {122, 46, 24, 15}, {122, 46, 24, 15}, {117, 47, 24, 15}, {118, 47, 24, 15}};
    private final int[][] Number_DataBlocks_Group2 = {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 2, 2}, {0, 0, 0, 0}, {0, 0, 4, 1}, {0, 2, 2, 2}, {0, 2, 4, 4}, {2, 1, 2, 2}, {0, 4, 4, 8}, {2, 2, 6, 4}, {0, 1, 4, 4}, {1, 5, 5, 5}, {1, 5, 7, 7}, {1, 3, 2, 13}, {5, 1, 15, 17}, {1, 4, 1, 19}, {4, 11, 4, 16}, {5, 13, 5, 10}, {4, 0, 6, 6}, {7, 0, 16, 0}, {5, 14, 14, 14}, {4, 14, 16, 2}, {4, 13, 22, 13}, {2, 4, 6, 4}, {4, 3, 26, 28}, {10, 23, 31, 31}, {7, 7, 37, 26}, {10, 10, 25, 25}, {3, 29, 1, 28}, {0, 23, 35, 35}, {1, 21, 19, 46}, {6, 23, 7, 1}, {7, 26, 14, 41}, {14, 34, 10, 64}, {4, 14, 10, 46}, {18, 32, 14, 32}, {4, 7, 22, 67}, {6, 31, 34, 61}};
    private final int[][] Number_Data_Codewords_In_Blocks_Group2 = {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 16, 12}, {0, 0, 0, 0}, {0, 0, 15, 14}, {0, 39, 19, 15}, {0, 37, 17, 13}, {69, 44, 20, 16}, {0, 51, 23, 13}, {93, 37, 21, 15}, {0, 38, 21, 12}, {116, 41, 17, 13}, {88, 42, 25, 13}, {99, 46, 20, 16}, {108, 47, 23, 15}, {121, 44, 23, 15}, {114, 45, 22, 14}, {108, 42, 25, 16}, {117, 0, 23, 17}, {112, 0, 25, 0}, {122, 48, 25, 16}, {118, 46, 25, 17}, {107, 48, 25, 16}, {115, 47, 23, 17}, {123, 46, 24, 16}, {118, 46, 25, 16}, {117, 46, 24, 16}, {116, 48, 25, 16}, {116, 47, 25, 16}, {0, 47, 25, 16}, {116, 47, 25, 16}, {116, 47, 25, 17}, {122, 48, 25, 16}, {122, 48, 25, 16}, {123, 47, 25, 16}, {123, 47, 25, 16}, {118, 48, 25, 16}, {119, 48, 25, 16}};
    private final int[] ExponentsOfAlpha = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255};
    private final int[] IntegerValue = {1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, 157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35, 70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161, 95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240, 253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226, 217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206, 129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204, 133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84, 168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115, 230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166, 81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9, 18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22, 44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1};
    int[] REMAINDER_BITS = {0, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0};

    private final int[][] ALIGNMENT_PATTERN_POSITIONS = {{6, 18}, {6, 22}, {6, 26}, {6, 30}, {6, 34}, {6, 22, 38}, {6, 24, 42}, {6, 26, 46}, {6, 28, 50}, {6, 30, 54}, {6, 32, 58}, {6, 34, 62}, {6, 26, 46, 66}, {6, 26, 48, 70}, {6, 26, 50, 74}, {6, 30, 54, 78}, {6, 30, 56, 82}, {6, 30, 58, 86}, {6, 34, 62, 90}, {6, 28, 50, 72, 94}, {6, 26, 50, 74, 98}, {6, 30, 54, 78, 102}, {6, 28, 54, 80, 106}, {6, 32, 58, 84, 110}, {6, 30, 58, 86, 114}, {6, 34, 62, 90, 118}, {6, 26, 50, 74, 98, 122}, {6, 30, 54, 78, 102, 126}, {6, 26, 52, 78, 104, 130}, {6, 30, 56, 82, 108, 134}, {6, 34, 60, 86, 112, 138}, {6, 30, 58, 86, 114, 142}, {6, 34, 62, 90, 118, 146}, {6, 30, 54, 78, 102, 126, 150}, {6, 24, 50, 76, 102, 128, 154}, {6, 28, 54, 80, 106, 132, 158}, {6, 32, 58, 84, 110, 136, 162}, {6, 26, 54, 82, 110, 138, 166}, {6, 30, 58, 86, 114, 142, 170}};
    int[] MASK_INFORMATION = {0b000111110010010100, 0b001000010110111100, 0b001001101010011001, 0b001010010011010011, 0b001011101111110110, 0b001100011101100010, 0b001101100001000111, 0b001110011000001101, 0b001111100100101000, 0b010000101101111000, 0b010001010001011101, 0b010010101000010111, 0b010011010100110010, 0b010100100110100110, 0b010101011010000011, 0b010110100011001001, 0b010111011111101100, 0b011000111011000100, 0b011001000111100001, 0b011010111110101011, 0b011011000010001110, 0b011100110000011010, 0b011101001100111111, 0b011110110101110101, 0b011111001001010000, 0b100000100111010101, 0b100001011011110000, 0b100010100010111010, 0b100011011110011111, 0b100100101100001011, 0b100101010000101110, 0b100110101001100100, 0b100111010101000001, 0b101000110001101001};
    int[][] MASK_BITS = {{0b111011111000100, 0b111001011110011, 0b111110110101010, 0b111100010011101, 0b110011000101111, 0b110001100011000, 0b110110001000001, 0b110100101110110}, {0b101010000010010, 0b101000100100101, 0b101111001111100, 0b101101101001011, 0b100010111111001, 0b100000011001110, 0b100111110010111, 0b100101010100000}, {0b011010101011111, 0b011000001101000, 0b011111100110001, 0b011101000000110, 0b010010010110100, 0b010000110000011, 0b010111011011010, 0b010101111101101}, {0b001011010001001, 0b001001110111110, 0b001110011100111, 0b001100111010000, 0b000011101100010, 0b000001001010101, 0b000110100001100, 0b000100000111011}};
    private final int LEVEL_TO_WRITE_VERSION = 6;

    //Modules
    private final int B = 0; // Black
    private final int W = 1; // White
    private final int F = -1; // Free
    private final int R = -2; //Reserved

    public int[][] fromUuid(String myString) throws Exception {
        //first get message array from string
        int[] bits_from_string = BuildBitString(myString);

        // so break up data in packs or blocks
        int[] data_from_blocks = MessageIntoBlocks(bits_from_string);

        // The next step is to put them in the QR code matrix along with the required function patterns
        return QrMatrix(data_from_blocks);
    }

    private int[] BuildBitString(String myString) throws Exception {
        byte[] strBytes = myString.getBytes(StandardCharsets.ISO_8859_1);
        int strSize = strBytes.length;
        List<Integer> bits = new ArrayList<>();

        //Determine the QrCode Level based on the Correction Level and message size
        for (int version = 0; version < 40; version++) {
            int capacity = BYTE_MODE_CAPACITY[version][CorrectionLevel];
            if (capacity >= strSize) {
                QrCodeLevel = version;
                break;
            }
        }

        if (QrCodeLevel == -1) throw new Exception("UUID is too large to fit in any QR code version");

        // Step: Build bit string:
        // - Mode(4 bits) +
        // - CharCount(8 or 16 bits, based on qr version) +
        // - data bytes (data converted to ISO 8859-1 or UTF-8, and them each char to byte)
        // - Break Up into 8-bit Codewords and Add Pad Bytes if Necessary:
        // - Add Terminator
        // -- get total codewords using TotalCodewors[QrCodeLevel][CorrectionLevel] and multiply by 8
        // -- if total is 104 (example), and i have <= 100 (total -4), i put only 4 0s at end, even if number was too short than total, example, 70. If i > 100 and < 104, fill with 0s
        // - Add More 0s to Make the Length a Multiple of 8
        // -- After adding the terminator, if the number of bits in the string is not a multiple of 8, first pad the string on the right with 0s to make the string's length a multiple of 8.

        AppendBits(bits, 0b0100, 4); // mode indicator for byte mode is 0100 -> Using byte modes because utf-8 compatible
        int lengthSize = QrCodeLevel >= 9 ? 16 : 8; //Version 1-9 (index = 0 to 8) = 8 bits length, others 16 bits
        AppendBits(bits, strSize, lengthSize);

        //Step 3: Encode Using the Selected Mode
        for (byte b : strBytes) AppendBits(bits, b & 0xFF, lengthSize);

        //Step 4: Break Up into 8-bit Codewords and Add Pad Bytes if Necessary
        //Determine the Required Number of Bits for this QR Code
        int TOTAL_DATA_CODEWORDS = Total_Codewords[QrCodeLevel][CorrectionLevel];
        int totalDataBits = TOTAL_DATA_CODEWORDS * 8;
        // Add terminator up to 4 zeros if needed
        int remaining = totalDataBits - bits.size();
        if (remaining > 0) {
            int terminator = Math.min(4, remaining);
            AppendBits(bits, 0, terminator);
        }

        // Add More 0s to Make the Length a Multiple of 8
        int actualSize = bits.size();
        if (actualSize % 8 != 0) {
            int nextMultipleOf8 = (actualSize + 7) & (-8);
            AppendBits(bits, 0, nextMultipleOf8 - actualSize); // will add 0s until complete the length
        }

        //Add Pad Bytes if the String is Still too Short
        remaining = totalDataBits - bits.size();
        int loops = remaining / 8; //104 - 80 / 8 = 3;
        //00010001 = 17, 11101100 = 236
        if ((loops & 1) == 0) {
            //if number is 2, run loops once and add 16 bits (236 and 17)
            loops /= 2;
            for (int i = 0; i < loops; i++) AppendBits(bits, 0b1110110000010001, 16); //add 236 and 17
        } else {
            //if number is 1, no loop, add 236. Number is 3, remove 1, divide by two, run loop once, add extra pack of 236
            loops -= 1;
            loops /= 2;
            for (int i = 0; i < loops; i++) AppendBits(bits, 0b1110110000010001, 16); //add 236 and 17
            AppendBits(bits, 0b11101100, 8); // if not multiple of 2, will need a extra pack o 8 bits at end (236)
        }

        if (bits.size() != totalDataBits) throw new Exception("Error when try to write data bit");

        if (debug) {
            System.out.printf("%n%n");
            System.out.println("Printing Data Bits in chunks of 8");
            for (int i = 0; i < totalDataBits; i += 8) {
                StringBuilder sb = new StringBuilder();
                for (int j = 0; j < 8; j++) sb.append(bits.get(i + j));
                System.out.printf("[%s]%n", sb);
            }
        }

        return bits.stream().mapToInt(Integer::intValue).toArray();
    }

    private int[] MessageIntoBlocks(int[] bit_string) throws Exception {
        int[] message_array = GenerateDividend_MessagePolynomial(bit_string);
        int errorCodePerBlock = EC_Codewords_Per_Block[QrCodeLevel][CorrectionLevel];
        if (Number_DataBlocks_Group1[QrCodeLevel][CorrectionLevel] > 1)
            return ChunkGroupsInBlocks(message_array, errorCodePerBlock); //has more than one block of data
        else {
            //has one block of data codewords, it means one set of error correction codewords for that block
            //in this case, simply place the error correction codewords after the data codewords and move on to the next step
            //i just need to attach error codeword in the end of data codeword
            int[] error_codewords_array = DividePolynomials(message_array, errorCodePerBlock);
            int error_size = error_codewords_array.length;
            int msg_size = message_array.length;
            int newSize = msg_size + error_size;
            int[] message_and_errors_codewords = new int[newSize];
            System.arraycopy(message_array, 0, message_and_errors_codewords, 0, message_array.length);
            for (int i = msg_size; i < newSize; i++) message_and_errors_codewords[i] = error_codewords_array[newSize - i - 1];

            int[] binary = new int[newSize * 8];
            for (int i = 0; i < newSize; i++) {
                int num = message_and_errors_codewords[i];// Process all 8 bits for each number
                for (int bit = 0; bit < 8; bit++) {// Calculate the correct position in the binary array
                    int pos = i * 8 + (7 - bit); // 7-bit to get MSB first
                    binary[pos] = (num >> bit) & 1;
                }
            }

            return binary;
        }
    }

    private int[][] QrMatrix(int[] data_from_blocks) {
        QrCodeSize = 21 + QrCodeLevel * 4;
        int[][] pattern_matrix = new int[QrCodeSize][QrCodeSize]; //a square;
        Arrays.stream(pattern_matrix).forEach(row -> Arrays.fill(row, F));

        AddFinderPatterns(pattern_matrix);
        AddReservedArea(pattern_matrix);
        AddAlignmentPatterns(pattern_matrix);
        AddTimingPatterns(pattern_matrix);
        if (debug) PrintQrCode(pattern_matrix);

        int[][][] mask_matrices = AddData(pattern_matrix, data_from_blocks);
        if (debug) PrintQrCode(mask_matrices[0]);
        int[][] best_mask_matrix = GetMaskWithBestScore(mask_matrices);

        best_mask_matrix = AddQuietZone(best_mask_matrix);// best_mask_matrix mask_matrices[0]
        if (debug) PrintQrCode(best_mask_matrix);
        else PrintQrLikeImage(best_mask_matrix);

        return best_mask_matrix;
    }

    /*
     *========================================================================================================================
     * Library to process QR CODE BIT IMAGE
     *========================================================================================================================
     */

    private void AddFinderPatterns(int[][] my_matrix) {
        // **The finder patterns are always placed in the TOP LEFT, TOP RIGHT AND BOTTOM LEFT CORNERS
        // of the QR code, no matter which version is in use.
        // The separators are lines of white modules placed beside the finder patterns to separate them from the rest
        int[][] find_pattern_top_left = new int[][]{
                {B, B, B, B, B, B, B, W},
                {B, W, W, W, W, W, B, W},
                {B, W, B, B, B, W, B, W},
                {B, W, B, B, B, W, B, W},
                {B, W, B, B, B, W, B, W},
                {B, W, W, W, W, W, B, W},
                {B, B, B, B, B, B, B, W},
                {W, W, W, W, W, W, W, W},
        };
        int[][] find_pattern_top_right = new int[][]{
                {W, B, B, B, B, B, B, B},
                {W, B, W, W, W, W, W, B},
                {W, B, W, B, B, B, W, B},
                {W, B, W, B, B, B, W, B},
                {W, B, W, B, B, B, W, B},
                {W, B, W, W, W, W, W, B},
                {W, B, B, B, B, B, B, B},
                {W, W, W, W, W, W, W, W},
        };
        int[][] find_pattern_bottom_left = new int[][]{
                {W, W, W, W, W, W, W, W},
                {B, B, B, B, B, B, B, W},
                {B, W, W, W, W, W, B, W},
                {B, W, B, B, B, W, B, W},
                {B, W, B, B, B, W, B, W},
                {B, W, B, B, B, W, B, W},
                {B, W, W, W, W, W, B, W},
                {B, B, B, B, B, B, B, W},
        };

        placePattern(my_matrix, 0, 0, find_pattern_top_left);
        placePattern(my_matrix, QrCodeSize - 8, 0, find_pattern_top_right);
        placePattern(my_matrix, 0, QrCodeSize - 8, find_pattern_bottom_left);
    }

    private void AddAlignmentPatterns(int[][] my_matrix) {
        if (QrCodeLevel < 1) return; // Place alignment patterns (if version >= 2)

        //For example, Version 2 has the numbers 6 and 18. This means that the CENTER MODULES
        // of the alignment patterns are to be placed at (6, 6), (6, 18), (18, 6) and (18, 18).
        int[][] alignmentPattern = {
                {B, B, B, B, B},
                {B, W, W, W, B},
                {B, W, B, W, B},
                {B, W, W, W, B},
                {B, B, B, B, B}
        };

        /*
         * HOWEVER, the alignment patterns must be put into the matrix AFTER the finder patterns
         * and separators have been placed, and the alignment patterns MUST NOT overlap the
         * finder patterns or separators.
         */
        int[] positions = ALIGNMENT_PATTERN_POSITIONS[QrCodeLevel-1];
        for (int x : positions) {
            for (int y : positions) {
                int ALIGNMENT_PATTERN_AUTHORIZE_PLACEMENT = 8;
                if (y < ALIGNMENT_PATTERN_AUTHORIZE_PLACEMENT || x < ALIGNMENT_PATTERN_AUTHORIZE_PLACEMENT)
                    continue;
                placePattern(my_matrix, x - 2, y - 2, alignmentPattern); //The position of array is the central position
            }
        }
    }

    private void AddTimingPatterns(int[][] my_matrix) {
        int Start = 6;//find pattern in array index
        int separator = 8;
        // Place timing patterns (alternating black and white)

        // Horizontal timing pattern
        for (int x = separator; x < QrCodeSize - Start - 2; x++)
            my_matrix[Start][x] = (x % 2 == 0) ? B : W;

        // Vertical timing pattern
        for (int y = separator; y < QrCodeSize - Start - 2; y++)
            my_matrix[y][Start] = (y % 2 == 0) ? B : W;

        //Dark Module
        my_matrix[QrCodeSize - 8][8] = B;
    }

    private void AddReservedArea(int[][] my_matrix) {
        for (int x = QrCodeSize - 8; x < QrCodeSize; x++) my_matrix[8][x] = R;
        for (int y = QrCodeSize - 8; y < QrCodeSize; y++) my_matrix[y][8] = R;
        for (int x = 0; x < 9; x++) my_matrix[8][x] = R;
        for (int y = 0; y < 9; y++) my_matrix[y][8] = R;

        if (QrCodeLevel >= LEVEL_TO_WRITE_VERSION) {
            for (int x = 0; x < 6; x++)
                for (int y = QrCodeSize - 11; y < QrCodeSize - 8; y++)
                    my_matrix[y][x] = R;

            for (int y = QrCodeSize - 11; y < QrCodeSize - 8; y++)
                for (int x = 0; x < 6; x++)
                    my_matrix[x][y] = R;
        }
    }

    private void placePattern(int[][] matrix, int startX, int startY, int[][] pattern) {
        int rows = pattern.length;
        int cols = pattern[0].length;
        for (int y = 0; y < rows; y++) {
            for (int x = 0; x < cols; x++) {
                if (startY + y < QrCodeSize && startX + x < QrCodeSize) {
                    matrix[startY + y][startX + x] = pattern[y][x];
                }
            }
        }
    }

    private int[][][] AddData(int[][] pattern_matrix, int[] dataFromBlocks) {
        // Place data bits in zig-zag pattern
        int dataIndex = 0;
        boolean goingUp = true;
        int dataSize = dataFromBlocks.length;
        int[][][] mask_matrices = new int[9][QrCodeSize][QrCodeSize];
        for (int i = 0; i < 9; i++)
            for (int j = 0; j < QrCodeSize; j++) //Write patterns in 8 models, 0 idx = original (without mask)
                System.arraycopy(pattern_matrix[j], 0, mask_matrices[i][j], 0, QrCodeSize);
//Make sure all data bits are used. If there are leftover [-] modules, assign 0 (white) to them after filling all codewords.
        for (int col = QrCodeSize - 1; col >= 0; col -= 2) {
            // Skip vertical timing pattern
            if (col == 6) col--;

            if (goingUp) {
                for (int row = QrCodeSize - 1; row >= 0; row--) {
                    if (dataIndex >= dataSize) continue;
                    if (pattern_matrix[row][col] == F)
                        dataIndex = placeDataBit(mask_matrices, row, col, dataFromBlocks, dataIndex);
                    if (dataIndex >= dataSize) continue;
                    if (pattern_matrix[row][col - 1] == F)
                        dataIndex = placeDataBit(mask_matrices, row, col - 1, dataFromBlocks, dataIndex);
                }
            } else {
                for (int row = 0; row < QrCodeSize; row++) {
                    if (dataIndex >= dataSize) continue;
                    if (pattern_matrix[row][col] == F)
                        dataIndex = placeDataBit(mask_matrices, row, col, dataFromBlocks, dataIndex);
                    if (dataIndex >= dataSize) continue;
                    if (pattern_matrix[row][col - 1] == F)
                        dataIndex = placeDataBit(mask_matrices, row, col - 1, dataFromBlocks, dataIndex);
                }
            }
            goingUp = !goingUp;
        }

        return mask_matrices;
    }

    private int[][] GetMaskWithBestScore(int[][][] mask_matrices) {
        int[] matrices_score = new int[9];

        for (int i = 0; i < 9; i++) {
            int[][] matrix = mask_matrices[i];
            int penalty = 0;

            // Rule 1: 5 or more modules with same color in line or column
            for (int row = 0; row < QrCodeSize; row++) {
                int equals_counter = 1;
                for (int col = 1; col < QrCodeSize; col++) {
                    //Looking for same color at horizontal (columns)
                    if (matrix[row][col] == matrix[row][col - 1]) equals_counter++;
                    else {
                        if (equals_counter >= 5) {
                            penalty += 3 + (equals_counter - 5);
                        }
                        equals_counter = 1;
                    }
                }
                if (equals_counter >= 5) penalty += 3 + (equals_counter - 5);
            }

            for (int row = 1; row < QrCodeSize; row++) {
                int equals_counter = 1;
                for (int col = 0; col < QrCodeSize; col++) {
                    //Looking for same color at vertical (rows)
                    if (matrix[row][col] == matrix[row - 1][col]) equals_counter++;
                    else {
                        if (equals_counter >= 5) {
                            penalty += 3 + (equals_counter - 5);
                        }
                        equals_counter = 1;
                    }
                }
                if (equals_counter >= 5) penalty += 3 + (equals_counter - 5);
            }

            // Rule 2: 2x2 areas with same color
            for (int row = 0; row < QrCodeSize - 1; row++) {
                for (int col = 0; col < QrCodeSize - 1; col++) {
                    int value = matrix[row][col];
                    if (matrix[row][col + 1] == value && matrix[row + 1][col] == value && matrix[row + 1][col + 1] == value)
                        penalty += 3;
                }
            }

            // Rule 3: The third rule gives the QR code a large penalty if there are patterns that look similar to
            // the finder patterns 1011101
            String p1 = "10111010000";
            String p2 = "00001011101";
            for (int row = 0; row < QrCodeSize; row++) {
                for (int col = 0; col <= QrCodeSize - 11; col++) {
                    StringBuilder sb = new StringBuilder(11);
                    for (int k = 0; k < 11; k++) sb.append(matrix[row][col + k]);
                    String s = sb.toString();
                    if (s.equals(p1) || s.equals(p2)) penalty += 40;
                }
            }
            for (int col = 0; col < QrCodeSize; col++) {
                for (int row = 0; row <= QrCodeSize - 11; row++) {
                    StringBuilder sb = new StringBuilder(11);
                    for (int k = 0; k < 11; k++) sb.append(matrix[row + k][col]);
                    String s = sb.toString();
                    if (s.equals(p1) || s.equals(p2)) penalty += 40;
                }
            }

            // Rule 4: Dark percentual proportion
            int total = QrCodeSize * QrCodeSize;
            int dark_modules = 0;
            for (int row = 0; row < QrCodeSize; row++)
                for (int col = 0; col < QrCodeSize; col++)
                    if (matrix[row][col] == B) dark_modules++;

            int darkPercent = (int) (((double) dark_modules / (double) total) * 100);
            int diff = darkPercent % 5;
            int prev5 = darkPercent - diff;
            int next5 = darkPercent + (5 - diff);
            int sub_prev = Math.abs(prev5 - 50) / 5;
            int sub_next = Math.abs(next5 - 50) / 5;
            penalty += Math.min(sub_prev, sub_next) * 10;
            matrices_score[i] = penalty;
        }

        int minor = 0;
        int idx = 0;
        for (int i = 0; i < 9; i++) {
            if (i == 0) minor = matrices_score[0];
            else if (matrices_score[i] < minor) {
                minor = matrices_score[i];
                idx = i;
            }
        }

        AddFormatStringAndVersionLevel(mask_matrices[idx], idx);
        return mask_matrices[idx];
    }

    private int placeDataBit(int[][][] mask_matrices, int row, int col, int[] data, int index) {
        int valueToAdd = data[index] == 0 ? W : B; // original data
        int invertedBit = valueToAdd == W ? B : W;
        mask_matrices[0][row][col] = valueToAdd;

        for (int i = 1; i < 9; i++) {
            if (i == 1) valueToAdd = (row + col) % 2 == 0 ? invertedBit : valueToAdd; // Mask 1
            else if (i == 2) valueToAdd = row % 2 == 0 ? invertedBit : valueToAdd; // Mask 2
            else if (i == 3) valueToAdd = col % 3 == 0 ? invertedBit : valueToAdd; // Mask 3
            else if (i == 4) valueToAdd = (row + col) % 3 == 0 ? invertedBit : valueToAdd; // Mask 4
            else if (i == 5) valueToAdd = (Math.floor((double) row / 2) + Math.floor((double) col / 3)) % 2 == 0 ? invertedBit : valueToAdd; // Mask 5
            else if (i == 6) valueToAdd = (((row * col) % 2) + ((row * col) % 3)) == 0 ? invertedBit : valueToAdd; // Mask 6
            else if (i == 7) valueToAdd = (((row * col) % 2) + ((row * col) % 3)) % 2 == 0 ? invertedBit : valueToAdd; // Mask 7
            else valueToAdd = (((row + col) % 2) + ((row + col) % 3)) % 2 == 0 ? invertedBit : valueToAdd; // Mask 8

            mask_matrices[i][row][col] = valueToAdd;
        }
        return ++index;
    }

    private void PrintQrCode(int[][] matrix) {
        int siz = matrix.length;
        System.out.println();
        for (int i = 0; i < siz; i++) {
            System.out.println();
            for (int j = 0; j < siz; j++) {
                if (matrix[i][j] == B) System.out.print("[ ]"); // black modules
                else if (matrix[i][j] == R) System.out.print("[R]"); // reserved modules
                else if (matrix[i][j] == W) System.out.print("[W]"); // white modules
                else if (matrix[i][j] == F) System.out.print("[-]"); //not used modules)
                else System.out.printf("[%d]", matrix[i][j]);
            }
        }
    }

    private void PrintQrLikeImage(int[][] matrix) {
        try {
            int size = matrix.length;
            int scale = 10; // pixels per module
            int imgSize = size * scale;
            BufferedImage img = new BufferedImage(imgSize, imgSize, BufferedImage.TYPE_INT_RGB);

            for (int y = 0; y < size; y++) {
                for (int x = 0; x < size; x++) {
                    int val = matrix[y][x] == B ? Color.BLACK.getRGB() : Color.WHITE.getRGB();
                    for (int dy = 0; dy < scale; dy++)
                        for (int dx = 0; dx < scale; dx++)
                            img.setRGB(x * scale + dx, y * scale + dy, val);
                }
            }

            File outFile = File.createTempFile("preciousweight-qr-", ".png");
            ImageIO.write(img, "png", outFile);
            System.out.println("Image saved to: " + outFile.getAbsolutePath());
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void AddFormatStringAndVersionLevel(int[][] best_score_matrix, int idx_mask) {
        if (idx_mask == 0) return;
        int data = MASK_BITS[CorrectionLevel][idx_mask - 1];

        int bitCounter = 0;
        //BottomLeft
        for (int y = QrCodeSize - 1; y >= QrCodeSize - 8; y--) {
            if (best_score_matrix[y][8] == R) {
                int mask = 1 << (14 - bitCounter);
                int bitValue = (data & mask) != 0 ? B : W;
                best_score_matrix[y][8] = bitValue;
                bitCounter++;
            }
        }

        //TopRight
        for (int x = QrCodeSize - 8; x < QrCodeSize; x++) {
            if (best_score_matrix[8][x] == R) {
                int mask = 1 << (14 - bitCounter);
                int bitValue = (data & mask) != 0 ? B : W;
                best_score_matrix[8][x] = bitValue;
                bitCounter++;
            }
        }

        //TopLeft
        bitCounter = 0;
        for (int x = 0; x < 9; x++) {
            if (best_score_matrix[8][x] == R) {
                int mask = 1 << (14 - bitCounter);
                int bitValue = (data & mask) != 0 ? B : W;
                best_score_matrix[8][x] = bitValue;
                bitCounter++;
            }
        }
        for (int y = 8; y >= 0; y--) {
            if (best_score_matrix[y][8] == R) {
                int mask = 1 << (14 - bitCounter);
                int bitValue = (data & mask) != 0 ? B : W;
                best_score_matrix[y][8] = bitValue;
                bitCounter++;
            }
        }

        if (QrCodeLevel >= LEVEL_TO_WRITE_VERSION) {
            int version_data = MASK_INFORMATION[QrCodeLevel - LEVEL_TO_WRITE_VERSION];
            int counter = 0;
            for (int x = 0; x < 6; x++)
                for (int y = QrCodeSize - 11; y < QrCodeSize - 8; y++)
                    if (best_score_matrix[y][x] == R) {
                        int mask = 1 << (17 - counter);
                        int bitValue = (version_data & mask) != 0 ? B : W;
                        best_score_matrix[y][x] = bitValue;
                        counter++;
                    }
            counter = 0;
            for (int row = 0; row < 6; row++)
                for (int y = QrCodeSize - 11; y < QrCodeSize - 8; y++)
                    if (best_score_matrix[row][y] == R) {
                        int mask = 1 << (17 - counter);
                        int bitValue = (version_data & mask) != 0 ? B : W;
                        best_score_matrix[row][y] = bitValue;
                        counter++;
                    }
        }
    }

    private int[][] AddQuietZone(int[][] matrix) {
        int newSize = matrix.length + 8;
        int[][] newMatrix = new int[newSize][newSize];
        Arrays.stream(newMatrix).forEach(row -> Arrays.fill(row, W)); // Fill with white modules

        for (int row = 4; row < newSize - 4; row++) {
//            System.arraycopy(matrix[row - 4], 0, newMatrix[row], 4, matrix.length);
            for(int k =0; k< matrix.length; k++){
                int idx = row-4;
                int value = matrix[idx][k] == F ? W : matrix[idx][k];
                newMatrix[row][k+4] = value;
            }
        }

        return newMatrix;
    }

    /*
     *========================================================================================================================
     * Library to process data
     *========================================================================================================================
     */
    private int[] GenerateDividend_MessagePolynomial(int[] bits) {
        boolean printDecimal = false;
        int chunkCount = (bits.length + 7) / 8;
        int[][] chunks = new int[chunkCount][8];

        // Split into 8-bit chunks
        for (int i = 0; i < chunkCount; i++) {
            int start = i * 8;
            int end = Math.min(start + 8, bits.length);
            int chunkSize = end - start;

            // Copy the chunk (pad with zeros if needed)
            System.arraycopy(bits, start, chunks[i], 0, chunkSize);
            if (chunkSize < 8) {
                Arrays.fill(chunks[i], chunkSize, 8, 0);
            }
        }

        int[] coefficients = new int[chunkCount];

        for (int i = 0; i < chunks.length; i++) {
            int[] chunk = chunks[i];
            int decimal = 0;
            int decimalToPrint = 0;

            // Convert binary array to decimal
            for (int j = 0; j < 8; j++) {
                decimal = (decimal << 1) | chunk[j];
                if (printDecimal) decimalToPrint += chunk[j] * (1 << (7 - j));
            }

            if (printDecimal) {
                char ascii = decimalToPrint < 32 || decimalToPrint > 126 ? ' ' : (char) decimalToPrint;
                System.out.printf("%5d | %s | %7d | %s%n",
                        i + 1,
                        Arrays.toString(chunk).replace(" ", ""),
                        decimalToPrint,
                        ascii == ' ' ? "(Non-printable)" : "'" + ascii + "'");
            }
            coefficients[i] = decimal;
        }
        return coefficients;
    }

    private int[] GenerateDivisor_GeneratorPolynomial(int polynomial_size) throws Exception {
        if (polynomial_size <= 2) throw new Exception("Invalid!");

        int[] new_polynomial = new int[3]; //new_pol[4] if size = 3, because x pow 0 or constant
        new_polynomial[0] = 1; //ɑ¹x0 -> x[0]= alpha 1, arr index  = x exponent
        new_polynomial[1] = 25; //ɑ25x¹ -> x[1]= alpha 25, arr value = alpha exponent
        new_polynomial[2] = 0; //ɑ0x² -> x[2]= alpha 0

        for (int pol_degree = 2; pol_degree < polynomial_size; pol_degree++) {
            int[] new_term = new int[]{pol_degree, 0};  //always have two components, alpha(0)x¹ - alpha(exponent)x0
            new_polynomial = ComputePolynomialMultiplication(new_polynomial, new_term);
        }
        return new_polynomial;
    }

    private int[] DividePolynomials(int[] message_array, int errorCodePerBlock) throws Exception {
        int[] generator_array = GenerateDivisor_GeneratorPolynomial(errorCodePerBlock);
        /*
        Now it is time to divide the message polynomial by the generator polynomial.
        //Generator is alpha based, message is integer based
        //The number of steps in the division must equal the number of terms in the message polynomial
        //The remainders of division will be the terms of correction codewords
        */
        int divSteps = message_array.length;
        int errorElements = generator_array.length;
        int newOrder = divSteps + errorElements;

        int[] messageWithNewSize = new int[newOrder];
        for (int i = divSteps - 1; i >= 0; i--) {
            messageWithNewSize[errorElements + i] = message_array[divSteps - i - 1];
        }

        for (int step = newOrder - 1; step > divSteps; step--) {
            //Step A Convert lead term to alpha
            int leadTerm = messageWithNewSize[step]; //last term of message array in x base (integer)
            if (leadTerm == 0) continue;
            int leadAlpha = GetAlphaFromIntegerBaseX(leadTerm);// Convert leadTerm to alpha exponent

            for (int multiplicationStep = errorElements - 1, s = 0; multiplicationStep >= 0; multiplicationStep--) {
                //Step A multiply lead term with generated array
                int alphaProduct = (generator_array[multiplicationStep] + leadAlpha) % 255;
                int productInt = GetIntegerBaseXFromAlpha(alphaProduct);
                //Step B: multiplication is over, i need to xor the result with the message polynomial
                messageWithNewSize[step - s] ^= productInt;
                s++;
                if (s > step) break;
            }
        }
        int[] ErrorCodewords = new int[divSteps];
        System.arraycopy(messageWithNewSize, 1, ErrorCodewords, 0, divSteps);
        return ErrorCodewords;
    }

    private int[] ChunkGroupsInBlocks(int[] bits, int ErrorCodePerBlock) throws Exception {
        // split data codewords in two groups, and in blocks inside groups the data are broken up sequentially
        int blocksNum_Group1 = Number_DataBlocks_Group1[QrCodeLevel][CorrectionLevel];
        int blocksNum_Group2 = Number_DataBlocks_Group2[QrCodeLevel][CorrectionLevel];
        int totalCodewordsInEachBlock_Group1 = Number_Data_Codewords_In_Blocks_Group1[QrCodeLevel][CorrectionLevel];
        int totalCodewordsInEachBlock_Group2 = Number_Data_Codewords_In_Blocks_Group2[QrCodeLevel][CorrectionLevel];

        int size = bits.length;
        int totalG1 = totalCodewordsInEachBlock_Group1 * blocksNum_Group1;
        int totalG2 = totalCodewordsInEachBlock_Group2 * blocksNum_Group2;

        int[][] G1 = new int[blocksNum_Group1][totalCodewordsInEachBlock_Group1];
        int[][] G2 = new int[blocksNum_Group2][totalCodewordsInEachBlock_Group2];
        List<Integer> already_used = new ArrayList<>();
        int[][] error_codes = new int[blocksNum_Group1 + blocksNum_Group2][ErrorCodePerBlock];

        int blockCounter = 0;
        int numberCounter = 0;
        if (blocksNum_Group1 > 0) {
            for (int i = 0; i < totalG1; i++) {
                if (i > 0 && i % totalCodewordsInEachBlock_Group1 == 0) {
                    error_codes[blockCounter] = DividePolynomials(G1[blockCounter], ErrorCodePerBlock);
                    numberCounter = 0;
                    blockCounter++;
                }
                G1[blockCounter][numberCounter] = bits[i];
                already_used.add(bits[i]);
                numberCounter++;
            }
            // Last block of G1
            error_codes[blockCounter] = DividePolynomials(G1[blockCounter], ErrorCodePerBlock);
        }

        if (blocksNum_Group2 > 0) {
            int add = already_used.size();
            already_used.clear();
            blockCounter = 0;
            numberCounter = 0;
            for (int i = 0; i < totalG2; i++) {
                if (i % totalCodewordsInEachBlock_Group2 == 0) {
                    error_codes[blockCounter] = DividePolynomials(G2[blockCounter], ErrorCodePerBlock);
                    numberCounter = 0;
                    blockCounter++;
                }
                G2[blockCounter][numberCounter] = bits[i + add];
                numberCounter++;
            }
            // Last block of G1
            error_codes[blockCounter] = DividePolynomials(G2[blockCounter], ErrorCodePerBlock);
        }
        return InterleaveBlocks(G1, G2, error_codes);
    }

    private int[] InterleaveBlocks(int[][] G1, int[][] G2, int[][] error_codes) {
        int blocksInG1 = G1.length;
        int sizeBlocksInG1 = G1[0].length;
        int blocksInG2 = G2.length;
        int sizeBlocksInG2 = blocksInG2 > 0 ? G2[0].length : 0;
        int blocksOfError = blocksInG1 + blocksInG2;
        int sizeBlocksOfError = error_codes[0].length;

        int[] result = new int[blocksInG1 * sizeBlocksInG1 + blocksInG2 * sizeBlocksInG2 + blocksOfError * sizeBlocksOfError];
        int counterResult = 0;
        for (int j = 0; j < sizeBlocksInG1; j++) {
            for (int i = 0; i < blocksOfError; i++) {
                result[counterResult] = i < blocksInG1 ? G1[i][j] : G2[i - blocksInG1][j];
                counterResult++;
            }
        }
        if (blocksInG2 > 0) { //last column of each block of G2
            for (int i = 0; i < blocksInG2; i++) {
                result[counterResult] = G2[i][sizeBlocksInG2 - 1];
                counterResult++;
            }
        }
        //ERROR CORRECTION CODE
        for (int j = 0; j < sizeBlocksOfError; j++) {
            for (int i = 0; i < blocksOfError; i++) {
                result[counterResult] = error_codes[i][j];
                counterResult++;
            }
        }

        //CONVERT HOLE ARRAY TO BINARY
        int totalBits = result.length * 8;
        int remainderBits = REMAINDER_BITS[QrCodeLevel];
        int[] binaryResult = new int[totalBits + remainderBits];
        int bitCounter = 0;
        for (int j = 0; j < result.length; j++) {
            int codeword = result[j]; // Convert each codeword to 8 bits (MSB first)
            for (int i = 7; i >= 0; i--)
                binaryResult[bitCounter++] = (codeword >> i) & 1;
        }
        for (int i = 0; i < remainderBits; i++)
            binaryResult[bitCounter + i] = 0;

        return binaryResult;
    }

    private int[] ComputePolynomialMultiplication(int[] old_polynomial, int[] new_term) throws Exception {
        int old_polynomial_size = old_polynomial.length;
        int new_term_size = new_term.length;
        int[] new_polynomial = new int[old_polynomial_size + new_term_size - 1];
        Arrays.fill(new_polynomial, -1);

        for (int i = 1; i <= old_polynomial_size; i++) {
            for (int j = 1; j <= new_term_size; j++) {
                int polynomial_idx = old_polynomial_size - i; //2-1=1;
                int new_term_idx = new_term_size - j; //3-1=2;

                //If there are any exponents that are larger than 255, fix them by putting them through the formula
                int alpha_exponent = FixExponentUsingFormula(new_term[new_term_idx], old_polynomial[polynomial_idx]);
                int new_pol_x_exponent = FixExponentUsingFormula(new_term_idx, polynomial_idx);

                if (new_polynomial[new_pol_x_exponent] != -1) {
                    //Combine terms -> Convert alphas to integer and xor them
                    int old_alpha_value_in_x_notation = GetIntegerBaseXFromAlpha(new_polynomial[new_pol_x_exponent]);
                    int new_alpha_value_in_x_notation = GetIntegerBaseXFromAlpha(alpha_exponent);
                    int new_alpha_exponent = old_alpha_value_in_x_notation ^ new_alpha_value_in_x_notation;
                    new_polynomial[new_pol_x_exponent] = GetAlphaFromIntegerBaseX(new_alpha_exponent);
                } else new_polynomial[new_pol_x_exponent] = alpha_exponent;
            }
        }
        return new_polynomial;
    }

    private void AppendBits(List<Integer> bits, int val, int length) {
        for (int i = length - 1; i >= 0; i--) bits.add((val >> i) & 1);
    }

    private int FixExponentUsingFormula(int a, int b) {
        int result = a + b;
        if (result > 255) result = (result % 256) + (int) Math.floor(result / 256);
        return result;
    }

    private int GetAlphaFromIntegerBaseX(int integer) throws Exception {
        int size = IntegerValue.length;
        int tgt = -1;
        for (int i = 0; i < size; i++) {
            if (IntegerValue[i] == integer) {
                tgt = ExponentsOfAlpha[i];
                break;
            }
        }
        if (tgt == -1) throw new Exception("Not found");
        return tgt;
    }

    private int GetIntegerBaseXFromAlpha(int exponent) throws Exception {
        int size = ExponentsOfAlpha.length;
        int tgt = -1;
        for (int i = 0; i < size; i++) {
            if (ExponentsOfAlpha[i] == exponent) {
                tgt = IntegerValue[i];
                break;
            }
        }
        if (tgt == -1) throw new Exception("Not found");
        return tgt;
    }
}
