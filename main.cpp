// ============================================================
// Autor: Edson Joel Carrera Avila
// main.cpp
// ============================================================

#include <iostream>
#include <iomanip>
#include <vector>

using namespace std;

extern "C" double vectorNormal(double* vec, int N);

int main() {
    int n;

    cout << "Ingresa la dimension del vector (N): ";
    cin >> n;

    vector<double> vec(n);

    cout << "\n--- DATOS DEL VECTOR ---" << endl;
    for (int i = 0; i < n; i++) {
        cout << "Ingresa el valor para vec[" << i << "]: ";
        cin >> vec[i];
    }

    double norma = vectorNormal(vec.data(), n);

    cout << "\n----------------------------------------\n";
    cout << "Resultado de la Norma del Vector: " << fixed << setprecision(6) << norma << endl;

    return 0;
}
