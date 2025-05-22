public class MethodVariableArgument {
    public static void main(String[] args) {
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
