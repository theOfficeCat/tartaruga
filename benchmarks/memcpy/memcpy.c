int a[256], b[256];

int main() {
    for (int i=0; i<256; i++) { a[i] = 5; }
    for (int i=0; i<256; i++) { b[i] = a[i]; }
    return b[0];
}
