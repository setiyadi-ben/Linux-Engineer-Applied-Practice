public class MethodParameter {
    public static void main(String[] args) {
        /*
         - Dengan method parameter kita bisa mengirim informasi kedalam method yang kita panggil
         dengan cara mengisi variabel pada method di bawah ini:
         */
        sayHello(null, null);
        sayHello("Eko", "Kurniawan");
        sayHello("Ben", "Ben");

    }
    // String firstName dan String lastName merupakan parameter argumen statement yang memungkinkan untuk
    // mengambil variabel melalui main method di atas
    // dipisahkan dengan koma dan bisa lebih dari 1 parameter
    static void sayHello(String firstName, String lastName){
        System.out.println("Hello " + firstName + " " + lastName);
    }

}
