public class TipeDataNumber {
    public static void main(String[] args) {
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
