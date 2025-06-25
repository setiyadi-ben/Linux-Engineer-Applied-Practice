public class Scope {
    public static void main(String[] args) {
        /*
         - Scope adalah area akses yang dapat di akses oleh variable
         - Sebagai contoh jika variable dibuat didalam method maka hanya akan
            bisa di akses didalam method tersebut dan ini berlaku juga jika
            variable ditulis didalam block.
         */
        // Contoh String berisi nama
        sayHello("Eko");
        // Contoh String kosong
        sayHello("");
    }
    static void sayHello(String name){
        // Area block method sayHello
        String hello = "Hello "+ name;

        // Mengecek apakah string terisi? jika terisi akan print Hi + name
        if(!name.isBlank()){
            String hi = "Hi "+ name;
            System.out.println(hi);
        }
        // Masih di area block method sayHello
        System.out.println(hello);
    }
}
