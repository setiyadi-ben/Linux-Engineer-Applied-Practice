public class Variable {
    public static void main(String[] args) {
        // Variable adlah tempat untuk menyimpan data

        // Java adalah bahasa static type, sehingga sebuah variable hanya bisa digunakan
        // untuk menyimpan tipe data yang sama, tidak bisa-berubah-ubah tipe data seperti 
        // di bahasa pemrograman PHP atau Javascript

        // Untuk membuat variable di Java kita bisa menggunakan nama tipe data lalu diikuti
        // dengan mnama variablenya

        //  Nama variable tidak boleh mengandung whitespace (spasi, enter, tab), dan tidak boleh
        //  seluruhnya number

        //  1. CARA PERTAMA DEFINISI DAHULU, INSERT DATA NANTI
        //  Untuk menyimpan data variable diawali dengan format tipedata variable;
        //  seperti contoh dibawah ini String name;
        String name;
        //  String default value = null;
        //  Karena Java itu case sensitive jadi penamaan name harus diturunkan sama persis yang di baris atasnya.
        //  kemudian di masukkan valuenya dan di print
        name = "Eko Kurniawan Khannedy";
        System.out.println(name);

        // 2. CARA KEDUA INSERT SECARA LANGSUNG SAAT DIDEFINISIKAN
        int age = 30;
        // int default value = 0;
        String address = "Indonesia";
        System.out.println(age);
        System.out.println(address);

        // Value variable dapat diganti, misalnya
        name = "Benny Hartanto Setiyadi";
        System.out.println(name);
        // Karena program Java di running dari atas ke bawah jadi penerapan semacam ini dapat dilakukan. 

        // 3. CARA KETIGA MENGGUNAKAN VAR AGAR DAPAT DIDETEKSI OTOMATIS
        // Sejak Java 10. Java mendukung pembuatan variable dengan kata kunci var tanpa menyebutkan tipe datanya
        // dengan syarat harus didefinisikan terlebih dahulu
        var firstName = "Benny";
        var middleName = "Hartanto";
        var lastName = "Setiyadi";
        var id = "27015";
        System.out.println(firstName);
        System.out.println(middleName);
        System.out.println(lastName);
        System.out.println(id);

        // 4. CARA KE EMPAT 


    }

}
