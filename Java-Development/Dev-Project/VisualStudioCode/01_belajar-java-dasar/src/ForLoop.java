public class ForLoop {
    public static void main(String[] args) {
        /*
         - For loop adalah salah satu kata kunci yang bisa digunakan untuk melakukan perulangan
         - Block kode yang terdapat di dalam for akan selalu diulangi selama kondisi for terpenuhi 
         - jika kondisi "true" perulangan akan diulangi dan jika "false" berulangan akan dihentikan
         Contoh sintaks perulangan for loop
         for (init satement; kondisi; post statement;)
         */

        // Contoh kode perulangan for loop tanpa henti
        // Sebaiknya jangan prnah gunakan ini karena akan menyebabkan program akan menjadi
        // "deadlock" atau stuck.
        // bisa dihentikan dengan cara klik terminal dan ctrl+c (hanya berlaku di vscode)
        // for(;;){
        //     System.out.println("Perulangan tanpa henti");
        // }

        // Contoh kode for loop
        var counter = 1; // init statement
        for(; counter <=10;){
            System.out.println("Perulangan " + counter);
            counter++;
        } 
        System.out.println(counter);

        // Contoh kode for loop 2 | memasukkan init statement kedalam for block
        // init satement hanya dieksekusi 1x
        for(var counter2 = 1; counter2 <=10;){
            System.out.println("Perulangan for loop 2 " + counter2);
            counter2++;
        } 
        // Untuk variasi kedua ini tidak dapat memprint nilai var counter2 dikarenakan
        // init statement tidak ditaruh diluar for loop statement

        // Contoh kode for loop 3 | memasukkan init statement dan post statement kedalam for block
        for(var counter2 = 1; counter2 <=10; counter2++){
            System.out.println("Perulangan for loop 3 " + counter2);
        } 

    }

}
