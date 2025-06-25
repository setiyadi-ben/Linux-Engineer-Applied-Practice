public class TipeDataNumber {
    public static void main(String[] args) {
        /*
        | Data Type | Min Value                          | Max Value                         | Size (bytes) |
        |-----------|------------------------------------|-----------------------------------|--------------|
        | byte      | -128                               | 127                               | 1            |
        | short     | -32768                             | 32767                             | 2            |
        | int       | -2147483648                        | 2147483647                        | 4            |
        | long      | -9223372036854775808               | 9223372036854775807               | 8            |
        | float     | -3.4028235E+38                     | 3.4028235E+38                     | 4            |
        | double    | -1.7976931348623157E+308           | 1.7976931348623157E+308           | 8            |

        bytes represent the amount of memory will be used for storing the data
        */

        byte iniByte = 100;
        short iniShort = 1000;
        int iniInt = 10000000;
        
        long iniLong = 1000000000;
        long iniLong2 = 1000000000000L;

        // Menyimpan file secara harfiah (what you see is what you get)
        int decimalInt = 34;
        // hex perlu ditambahkan 0x
        int hexaDecimal = 0xFFFFFF; 
        // binary perlu ditambahkan 0b
        int binaryDcimal = 0b1010101010;

        // UNDERSCORE digunakan untuk memudahkan readibility terhadap angka dalam jumlah banyak
        long balance = 1_000_000_000L;
        int amount = 1_000_000_000;
        int sum = 60_000_000;


    }

}
 