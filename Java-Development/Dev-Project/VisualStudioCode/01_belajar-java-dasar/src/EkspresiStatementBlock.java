public class EkspresiStatementBlock {
    public static void main(String[] args) {
        /*
        Ekspression adalah konstruksi dari variablel, operator dan
        pemanggilan method yang mengevaluasi menjadi sebuah single value
        Ekspression merupakan core component dari sebuah statement
         */

        // Contoh expression
        // intinya variable yang terdapat 1 value yang dideklarasikan
        int value;
        value = 10;

        
        /*
         - Statement merupakan kalimat lengkap dalam bahasa
         - Statement berisikan execution komplit, biasannya diakhiri dengan titik koma.
         Jenis-jenis statement:
         1. Assigment expression
         2. ++ dan --
         3. Method invocation
         4. Object creation expression
         */
        // Contoh statement
        System.out.println();

        // Assigment statement
        double aValue = 8933.234;
        // Increment statement
        aValue++;
        // Method invocation statement
        System.out.println("Hello World!");
        // Object creation statement
        // Date date = new Date();

        /*
         - Block merupakan kumpulan statement yang terdiri dari 0 atau lebih statement\
         - Block diawali dengan kurung kurawal {}
         */
        // Contoh block
        {
            System.out.println("Hello world 1");
            System.out.println("Hello world 2");
            System.out.println("Hello world 3");

            // Contoh block didalam block
            {
                System.out.println("Hello world 4");
                System.out.println("Hello world 5");
                System.out.println("Hello world 6");

                {
                    {
                        {
                            // bisa dilanjut terus sampai delama palung mariana;
                            // Fungsi dasar dari block ini adalah untuk meng-group beberpa statement agar lebih terorganisir
                        }
                    }
                }
            } 
        }

    }
}
