public class SwitchStatement {
    public static void main(String[] args) {
        /*
         - Switch adalah statement percabangan yang sama dengan if. Namun lebih sederhana
         - kondisi switch hanya berlaku untuk perbandingan '=='
         */

         // Contoh basic switch statement
         var nilai ="A";
         switch (nilai) {
            case "A":
                System.out.println("Wow, anda lulus dengan baik");
            break;
            case "B":
            case "C":
                System.out.println("Nilai anda cukup baik");
            break;
            case "D":
                System.out.println("Anda tidak lulus");
            break;
         
            default:
                break;
         }

        // SWITCH LAMBDA
        /*
         - Digunakan untuk memepermudah switch expression dengan meninggalkan
         break;
         */
        String ucapan;
        switch (nilai) {
            case "A" -> ucapan = "Wow, anda lulus dengan baik";
            case "B", "C" -> ucapan = "Nilai anda cukup baik";
            case "D" -> ucapan = "Anda tidak lulus";
                
            default -> {
                ucapan = "Mungkin anda salah jurusan";       
            }
        }
        System.out.println(ucapan);

        // Menyingkat Switch lambda dengan "yield"
        ucapan = switch (nilai) {
            case "A":
                yield "Wow, anda lulus dengan baik";
            case "B", "C":
                yield "Nilai anda cukup baik";
            case "D":
                yield "Anda tidak lulus";
            default:
                yield "Mungkin anda salah jurusan";  
        };
        System.out.println(ucapan);
    }
}
