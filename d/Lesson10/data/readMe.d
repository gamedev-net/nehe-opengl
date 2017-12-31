import std.stream;

int main(char[][] args)
{
    char[] c;
    char[] fn;
    

    File f = new File("world.txt");
    while (!f.eof())
    {
        c = f.readLine();
        printf("%.*s\n", c);
    }
    
    f.close();    

    return 0;

}