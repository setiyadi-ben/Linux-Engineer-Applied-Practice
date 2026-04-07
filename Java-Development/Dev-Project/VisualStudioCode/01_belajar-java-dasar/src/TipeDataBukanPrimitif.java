public class TipeDataBukanPrimitif {
    public static void main(String[] args) {
        // PEMROGRAMAN BAHASA JAVA ITU BERORIENTASI Object  ATAU OOP
        // number, char boolean adalah tipe primitif dan memiliki default value
        // String bukan tipe data primitif, tidak memiliki default value dan bernilai null
        // Di Java, semua tipe data primitif memiliki representasi tipe data bukan primitifnya yaitu Object
        
        // Representasi Tipe Data Primitif dari primitif ke bukan primitif
        // byte --> Byte
        // short --> Short
        // int --> Integer
        // long --> Long
        // float --> Float
        // double --> Double
        // char --> Character
        // boolean --> Boolean

        // Contoh penerapan seperti dibawah ini dan berbagai macam variasinya
        Integer iniInteger = 100;
        Long iniLong = 10000L;

        //  Contoh penerapan yang salah Byte iniByte;
        Byte iniByte = null;
        System.out.println(iniByte);

        iniByte = 100;
        System.out.println(iniByte);

        // Menkonversi primitif ke bukan primitif
        int iniInt = 100;
        Integer iniInteger2 = iniInt;
        System.out.println(iniInteger2);

        // Masih primitif ke bukan primitif namun beda tipe data
        Integer iniObject = iniInt;

        short iniShort = iniObject.shortValue();
        long iniLong2 = iniObject.longValue();
        float iniFloat = iniObject.floatValue();
        System.out.println(iniShort);
        System.out.println(iniLong2);
        System.out.println(iniFloat);

        Long amount = 100000L;
        

    }

}