public class IfStatement {
    public static void main(String[] args) {
        /*
         - Dalam Java, if merupakan salah satu kata kunci yang digunakan untuk percabangan
         - Percabangan artinya kita bisa mengekseskusi kode program tertentu ketika suatu kondisi terpenuhi
         - Hampir semua bahasa pemrogramman mendukung if statement
         */
        var nilai = 70;
        var absen = 90;

        // Jika diterapkan secara langsung
        // if akan mengeksekusi perintah boolean yang bernilai true
        if (nilai >=70 && absen >=75) {
            System.out.println("Selamat Anda Lulus");
        }

        // Jika dijabarkan || verbose atau bertele-tele
        var nilai2 = 70;
        var absen2 = 90;

        var lulusNilai = nilai >=75;
        var lulusAbsen = nilai >=75;

        var Lulus = lulusNilai && lulusAbsen;
        if (Lulus) {
            System.out.println("Selamat anda lulus untuk ke2 kalinya");
        }else{ //else akan mengeksekusi perintah if boolean yang bernilai false
            System.out.println("Silahkan coba lagi tahun depan");
        }

        // Jika memiliki kasus percabangan yang kompleks
        if (nilai >=80 && absen >=80) {
            System.out.println("nilai anda A");
        }else if (nilai >=70 && absen >=70) {
           System.out.println("nilai anda B"); 
        }else if (nilai >=60 && absen >=60) {
            System.out.println("Nilai anda C");
        }else if (nilai >50 && absen >=50 ) {
            System.out.println("nilai anda D");
        }else { // else tidak perlu diberikan kondisi (nilai >=80 && absen >=80)
            System.out.println("Nilai anda E");
        }
    }

}
