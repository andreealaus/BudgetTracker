# BudgetTracker

**BudgetTracker** este o aplicație de gestionare a bugetului dezvoltată cu SwiftUI, care ajută utilizatorii să gestioneze tranzacții, categorii, rapoarte și bugete. Aplicația folosește **Core Data** pentru stocarea persistentă a datelor și include funcționalități precum crearea de tranzacții prin OCR, planificarea bugetului pentru categoriile de cheltuieli, notificarea la depășirea acestora și generarea de rapoarte lunare.

---

## **Repository**

Codul sursă complet este disponibil la următoarea adresă:  
[BudgetTracker](https://github.com/andreealaus/BudgetTracker.git)

---

## **Cerințe**

Pentru a rula acest proiect, sunt necesare:
- macOS 12.0 sau versiune mai nouă
- Xcode 14.0 sau versiune mai nouă
- Swift 5.0 sau mai recent

---

## **Funcționalități**

- Autentificare utilizator și acces bazat pe rol (administrator și utilizator obișnuit);
- Gestionarea tranzacțiilor cu categorii de venituri și cheltuieli;
- Scanarea OCR a bonurilor pentru crearea automată a tranzacțiilor;
- Rapoarte lunare ce sumarizează veniturile și cheltuielile;
- Alerte la depășirea bugetului;
- Integrare cu Core Data pentru persistența datelor.

---

## **Livrabile**

- Codul sursă complet este disponibil în repository-ul menționat mai sus.

---

## **Instrucțiuni de instalare și rulare**

### **1. Clonarea repository-ului**
Deschideți terminalul și rulați următoarea comandă:
```bash
git clone https://github.com/andreealaus/BudgetTracker.git
```

### **2. Deschiderea proiectului în Xcode**
Navigați în folderul proiectului și deschideți fișierul `BudgetTracker.xcodeproj`.

### **3. Compilarea și rularea aplicației**
- Selectați dispozitivul țintă în Xcode (Iphone).
- Apăsați butonul *Run* sau combinația de taste `Cmd + R`.
- Aplicația se va lansa în simulator, unde puteți crea un cont de utilizator și puteți începe folosirea aplicației.
