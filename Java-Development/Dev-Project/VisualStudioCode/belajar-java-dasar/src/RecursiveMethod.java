public class RecursiveMethod {
    public static void main(String[] args) {
        /*
         - Recursive method merupakan kemampuan method memanggil dirinya sendiri
         - Beberapa problem dapat diselesaikan menggunakan recursive method seperti
            halnya kasus factorial (mengkali bilangan itu sendiri)
         */
        // Memanggil method factorial yang menggunakan for loop
        System.out.println(factorialLoop(5));
        // memanggil method factorial yang menggunakan recursive
        System.out.println(factorialRecursive(5));
    }

    // Menggunakan for loop untuk menyelesaikan perkalian faktorial
    static int factorialLoop(int value){
        var result = 1;

        // counter = 1 dan akan terus naik sampai batas yang ditentukan
        // oleh System.out.println(factorialLoop(5));
        for(var counter = 1; counter<= value; counter++){
            result *= counter;
        }
        return result;
    }

    // Menggunakan metode recursif
    static int factorialRecursive(int value){
        if(value == 1){
            // jika nilai value setara dengan 1, kembali nilai 1
            return 1;
        }else{ // jika tidak
            // kembali nilai value dikali nilai rekursif yang menurun
            // karena setiap tingkat dikurangi 1
            return value * factorialRecursive(value - 1);
        }
    }
}
