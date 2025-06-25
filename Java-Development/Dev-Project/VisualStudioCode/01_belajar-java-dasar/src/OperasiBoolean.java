public class OperasiBoolean {
    public static void main(String[] args) {
        /*
         * MACAM-MACAM OPERASI BOOLEAN:
         * Sama seperti gerbang logika yang dipelajari di saat SMK & Kuliah dulu
         * Terdapat gerbang AND, OR dan NOT || Konsep input dan outputnya juga sama. 
           &&   || Dan          || AND
           ||   || Atau         || OR
           !    || Kebalikan    || NOT
         */
        var absen = 70;
        var nilaiakhir = 80;

        // Operasi perbandingan Boolean
        var lulusAbsen = absen>=75;
        var lulusNilaiAkhir = nilaiakhir>=75;

        // Mengeksekusi operasi boolean
        var lulus = lulusAbsen && lulusNilaiAkhir;
        // sebagai alternatif bisa ditulis dengan deklarasi tipe data boolean
        // Operasi perbandingan Boolean
        // boolean lulusAbsen = absen>=75;
        // boolean lulusNilaiAkhir = nilaiakhir>=75;

        // boolean lulus = lulusAbsen && lulusNilaiAkhir;
        System.out.println(lulus);

    }

}
