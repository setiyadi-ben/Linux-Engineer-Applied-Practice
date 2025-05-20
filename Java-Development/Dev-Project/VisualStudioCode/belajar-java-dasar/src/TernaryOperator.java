public class TernaryOperator {
    public static void main(String[] args) {
        /*
         Ternary operator merupakan operator sederhana dari if statement.
         Ia akan mengevaluasi input data yang dimasukkan, jika "true" maka nilai
         pertama yang diambil. Jika false makan nilai kedua yang akan diambil
         */

         // CONTOH BILA MENGGUNAKAKAN IF ELSE
         var nilai = 75;
         String ucapan;

         if (nilai >=75) {
            ucapan = "Selamat anda lulus";
         }else {
            ucapan = "Silahkan coba lagi";
         }
         System.out.println(ucapan);

         // CONTOH BILA MENGGUNAKAN TERNARY OPERATOR
         // JADI LEBIH SINGKAT
         String ucapan2 = nilai >= 75? "Slamat anda lulus" : "Silahkan coba lagi";
         System.out.println(ucapan2); 
    }

}
