/* =========================================================
   DANE TESTOWE
   ========================================================= */

-- 1. Dodanie kierowcy
INSERT INTO Kierowcy (imie, nazwisko, dzial, stanowisko)
VALUES (N'Jan', N'Kowalski', N'Transport', N'Kierowca');

-- 2. Dodanie pojazdu
INSERT INTO Pojazd (
    marka,
    model,
    numer_rejestracyjny,
    typ_wlasnosci,
    rodzaj_paliwa,
    srednie_spalanie_100km,
    cena_paliwa_za_litr
)
VALUES (
    N'Skoda',
    N'Octavia',
    N'SBI12345',
    N'służbowy',
    N'diesel',
    7.50,
    6.40
);

-- 3. Dodanie prawa jazdy
INSERT INTO PrawoJazdy (
    numer_prawa_jazdy,
    data_wydania,
    data_waznosci,
    id_kierowcy
)
VALUES (
    N'ABC123456',
    '2020-01-01',
    '2030-01-01',
    1
);

-- 4. Dodanie kategorii prawa jazdy
INSERT INTO KategoriaPrawaJazdy (nazwa_kategorii)
VALUES (N'B');

-- 5. Przypisanie kategorii do prawa jazdy
INSERT INTO PrawoJazdy_Kategoria (id_prawa_jazdy, id_kategorii)
VALUES (1, 1);



/* =========================================================
   TEST 1
   Trigger sprawdzający ważność prawa jazdy
   ========================================================= */

-- Test poprawny: powinien się wykonać poprawnie
EXEC DodajPrzejazd
    @data_przejazdu = '2026-05-28',
    @cel_przejazdu = N'delegacja',
    @trasa = N'Bielsko-Biała - Katowice',
    @liczba_kilometrow = 50,
    @stan_licznika_przed = 12000,
    @stan_licznika_po = 12070,
    @id_kierowcy = 1,
    @id_pojazdu = 1;

-- Ustawienie nieważnego prawa jazdy
UPDATE PrawoJazdy
SET data_waznosci = '2025-01-01'
WHERE id_prawa_jazdy = 1;

-- Test błędny: powinien zostać zablokowany przez trigger
EXEC DodajPrzejazd
    @data_przejazdu = '2026-05-28',
    @cel_przejazdu = N'wyjazd służbowy',
    @trasa = N'Bielsko-Biała - Kraków',
    @liczba_kilometrow = 80,
    @stan_licznika_przed = 13000,
    @stan_licznika_po = 13090,
    @id_kierowcy = 1,
    @id_pojazdu = 1;

-- Przywrócenie poprawnej daty ważności prawa jazdy
UPDATE PrawoJazdy
SET data_waznosci = '2030-01-01'
WHERE id_prawa_jazdy = 1;



/* =========================================================
   TEST 2
   Trigger sprawdzający zgodność daty kosztu z datą przejazdu
   ========================================================= */

-- Dodanie poprawnego przejazdu do testu kosztów
EXEC DodajPrzejazd
    @data_przejazdu = '2026-05-30',
    @cel_przejazdu = N'spotkanie',
    @trasa = N'Bielsko-Biała - Żywiec',
    @liczba_kilometrow = 20,
    @stan_licznika_przed = 14000,
    @stan_licznika_po = 14025,
    @id_kierowcy = 1,
    @id_pojazdu = 1;

-- Test poprawny: koszt z datą zgodną z przejazdem
INSERT INTO Koszty (
    rodzaj_kosztu,
    kwota,
    data_kosztu,
    opis,
    id_przejazdu
)
VALUES (
    N'paliwo',
    50.00,
    '2026-05-30',
    N'tankowanie',
    2
);

-- Test błędny: koszt z datą wcześniejszą niż przejazd
INSERT INTO Koszty (
    rodzaj_kosztu,
    kwota,
    data_kosztu,
    opis,
    id_przejazdu
)
VALUES (
    N'parking',
    10.00,
    '2026-05-25',
    N'parking przed przejazdem',
    2
);



/* =========================================================
   TEST 3
   Procedura DodajPrzejazd
   ========================================================= */

-- Test poprawny
EXEC DodajPrzejazd
    @data_przejazdu = '2026-06-01',
    @cel_przejazdu = N'kontrola',
    @trasa = N'Bielsko-Biała - Cieszyn',
    @liczba_kilometrow = 60,
    @stan_licznika_przed = 15000,
    @stan_licznika_po = 15070,
    @id_kierowcy = 1,
    @id_pojazdu = 1;

-- Test z nieistniejącym kierowcą: powinien się nie wykonać przez FK
EXEC DodajPrzejazd
    @data_przejazdu = '2026-06-02',
    @cel_przejazdu = N'kontrola',
    @trasa = N'Bielsko-Biała - Cieszyn',
    @liczba_kilometrow = 30,
    @stan_licznika_przed = 15100,
    @stan_licznika_po = 15140,
    @id_kierowcy = 999,
    @id_pojazdu = 1;



/* =========================================================
   TEST 4
   Funkcja wyliczająca orientacyjny koszt paliwa
   ========================================================= */

SELECT dbo.FN_WyliczKosztPaliwa(120, 7.50, 6.40) AS koszt_paliwa;
SELECT dbo.FN_WyliczKosztPaliwa(50, 6.80, 6.20) AS koszt_paliwa;
SELECT dbo.FN_WyliczKosztPaliwa(200, 8.10, 6.55) AS koszt_paliwa;



/* =========================================================
   PODGLĄD DANYCH PO TESTACH
   ========================================================= */

SELECT * FROM Kierowcy;
SELECT * FROM PrawoJazdy;
SELECT * FROM KategoriaPrawaJazdy;
SELECT * FROM PrawoJazdy_Kategoria;
SELECT * FROM Pojazd;
SELECT * FROM Przejazd;
SELECT * FROM Koszty;
 