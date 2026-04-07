public class MethodVariableArgument {
    public static void main(String[] args) {
        /*
         - Method Variable Argument digunakan untuk memfasilitasi pengiriman
            data dalam jumlah yang tidak pasti, bisa 0 atau lebih
         - Data yang dikirim berbentuk array dengan cara mengubah "[]" menjadi "..."
            didalam block method statementnya
         */

        // Tanpa menggunakan variable argument
        int[] values = {80, 80, 80, 80, 80};
        sayCongrats("Eko", values);

        // Menggunakan variable argument
        saySelamat("Ryzen", 80, 70, 40, 40);
    }

    // Tanpa menggunakan variable argument
    static void sayCongrats(String name, int []values){
        var total = 0;
        for(var value: values){
            total +=value;
        }
        var finalValue = total / values.length;

        if(finalValue >=75){
            System.out.println("Selamat "+ name +", Anda Lulus");
        }else{
            System.out.println("Maaf "+ name +", Anda Tidak Lulus");
        }
    }

    // Menggunakan variable argument
    static void saySelamat(String name, int... values){
        var total = 0;
        for(var value: values){
            total +=value;
        }
        var finalValue = total / values.length;

        if(finalValue >=75){
            System.out.println("Selamat "+ name +", Anda Lulus");
        }else{
            System.out.println("Maaf "+ name +", Anda Tidak Lulus");
        }
    }

}
