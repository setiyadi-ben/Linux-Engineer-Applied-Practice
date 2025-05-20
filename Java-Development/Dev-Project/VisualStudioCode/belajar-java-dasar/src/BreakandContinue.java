public class BreakandContinue {
    public static void main(String[] args) {
        /*
         - Break digunakan untuk menghentikan seluruh perulangan
         - Continue digunakan untuk menghentikan perulangan saat ini,
         kemudian melanjutkan perhitungan selanjutnya. 
         */
        var counter = 1;

        while (true){
            System.out.println("Perulangan " + counter);
            // infinite looping | while (true)
            counter++;

            if (counter > 10){
                // mematikan seluruh perulangan yang dilakukan oleh
                // do while
                break;
            }
        }
        System.out.println("Perulangan terhenti oleh break;");

        for(var counter2 = 1; counter2 <=100; counter2++){
            // Jika di modulo  2 (dibagi, dan hasil baginya) 0 atau habis
            if (counter2 %2 == 0) {
                // hentikan bilangan genap seperti 2, 4, 6, ..., 100
                // lanjutkan 1, 3, 5, ..., 99
                continue;
            }
            System.out.println("Perulangan ganjil " + counter2);
        }
    }

}
