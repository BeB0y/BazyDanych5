/*1. Trigger sprawdzający ważność prawa jazdy*/

DROP TRIGGER IF EXISTS TRG_Przejazd_SprawdzPrawoJazdy; 

GO 

  

CREATE TRIGGER TRG_Przejazd_SprawdzPrawoJazdy 

ON Przejazd 

AFTER INSERT, UPDATE 

AS 

BEGIN 

    SET NOCOUNT ON; 

  

    IF EXISTS ( 

        SELECT 1 

        FROM inserted i 

        LEFT JOIN PrawoJazdy pj 

            ON i.id_kierowcy = pj.id_kierowcy 

        WHERE pj.id_prawa_jazdy IS NULL 

           OR i.data_przejazdu < pj.data_wydania 

           OR i.data_przejazdu > pj.data_waznosci 

    ) 

    BEGIN 

        RAISERROR (N'Nie można zapisać przejazdu. Kierowca nie posiada ważnego prawa jazdy w dniu przejazdu.', 16, 1); 

        ROLLBACK TRANSACTION; 

        RETURN; 

    END 

END; 

GO 

/*2. Trigger sprawdzający zgodność daty kosztu z datą przejazdu*/

DROP TRIGGER IF EXISTS TRG_Koszty_SprawdzDate; 

GO 

  

CREATE TRIGGER TRG_Koszty_SprawdzDate 

ON Koszty 

AFTER INSERT, UPDATE 

AS 

BEGIN 

    SET NOCOUNT ON; 

  

    IF EXISTS ( 

        SELECT 1 

        FROM inserted i 

        JOIN Przejazd p 

            ON i.id_przejazdu = p.id_przejazdu 

        WHERE i.data_kosztu < p.data_przejazdu 

    ) 

    BEGIN 

        RAISERROR (N'Data kosztu nie może być wcześniejsza niż data przejazdu.', 16, 1); 

        ROLLBACK TRANSACTION; 

        RETURN; 

    END 

END; 

GO 

/*3. Procedura składowana dodająca przejazd (użytkownik nie musi samodzielnie budować instrukcji INSERT.) */

DROP PROCEDURE IF EXISTS DodajPrzejazd; 

GO 

  

CREATE PROCEDURE DodajPrzejazd 

    @data_przejazdu DATE, 

    @cel_przejazdu NVARCHAR(100), 

    @trasa NVARCHAR(150), 

    @liczba_kilometrow DECIMAL(8,2), 

    @stan_licznika_przed DECIMAL(10,2), 

    @stan_licznika_po DECIMAL(10,2), 

    @id_kierowcy INT, 

    @id_pojazdu INT 

AS 

BEGIN 

    SET NOCOUNT ON; 

  

    INSERT INTO Przejazd ( 

        data_przejazdu, 

        cel_przejazdu, 

        trasa, 

        liczba_kilometrow, 

        stan_licznika_przed, 

        stan_licznika_po, 

        id_kierowcy, 

        id_pojazdu 

    ) 

    VALUES ( 

        @data_przejazdu, 

        @cel_przejazdu, 

        @trasa, 

        @liczba_kilometrow, 

        @stan_licznika_przed, 

        @stan_licznika_po, 

        @id_kierowcy, 

        @id_pojazdu 

    ); 

END; 

GO 

/*4. Funkcja wyliczająca orientacyjny koszt paliwa */

DROP FUNCTION IF EXISTS dbo.FN_WyliczKosztPaliwa; GO 

CREATE FUNCTION dbo.FN_WyliczKosztPaliwa  

(  

@liczba_kilometrow DECIMAL(8,2), 

 @srednie_spalanie_100km DECIMAL(5,2),  

@cena_paliwa_za_litr DECIMAL(6,2)  

)  

RETURNS DECIMAL(10,2)  

AS  

BEGIN  

DECLARE @wynik DECIMAL(10,2); 

SET @wynik = (@liczba_kilometrow / 100.0) * @srednie_spalanie_100km * @cena_paliwa_za_litr; 
 
RETURN @wynik; 
 

END; GO 

 

 