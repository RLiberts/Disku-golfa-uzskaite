DROP VIEW IF EXISTS Lietotaju_Rekordu_Tabula;
DROP VIEW IF EXISTS vw_Trases_PAR;
GO
--Skats saskaita trases PAR vertibu
CREATE VIEW vw_Trases_PAR AS SELECT 
T.Trase_ID,
ISNULL(SUM(G.PAR_vertiba), 0) AS Trases_PAR
FROM Trase T
LEFT JOIN Grozs G ON T.Trase_ID = G.Trases_ID
GROUP BY T.Trase_ID;
GO

--1.Visu trašu saraksts ar apsaimniekotāja vārdu, sakartots dilstosa seciba pec izveides
SELECT
T.Trase_ID,
T.Nosaukums AS Trase,
T.Grozu_skaits,
VW.Trases_PAR,
T.Grutibas_pakape,
L.Lietotajvards AS Apsaimniekotajs,
T.Izveidota
FROM Trase T
JOIN Apsaimniekotajs A ON T.Apsaimniekotajs_ID = A.Apsaimniekotajs_ID
JOIN Lietotajs L ON A.Lietotaja_ID = L.Lietotaja_ID
LEFT JOIN vw_Trases_PAR VW ON T.Trase_ID = VW.Trase_ID
ORDER BY T.Izveidota DESC;
GO

--2.Top 5 lietotāji pēc kopējā raundos pavadīto spēļu skaita
SELECT TOP 5
L.Lietotajvards,
L.Pieredze,
COUNT(RS.Raunda_ID) AS Raundi_kopa
FROM Lietotajs L
JOIN Raunda_Speletajs RS ON L.Lietotaja_ID = RS.Lietotaja_ID
GROUP BY L.Lietotajvards, L.Pieredze
ORDER BY Raundi_kopa DESC;
GO
--3.Vidējais vērtējums katrai trasei ar atsauksmju skaitu
SELECT
T.Nosaukums AS Trase,
T.Grutibas_pakape,
COUNT(TA.Atsauksmes_ID) AS Atsauksmju_skaits,
ISNULL(CAST(ROUND(AVG(CAST(TA.Vertejums AS DECIMAL(4,2))), 2) AS DECIMAL(4,2)), 0.00) AS Videjais_vertejums,
MIN(TA.Vertejums) AS Min_vertejums,
MAX(TA.Vertejums) AS Max_vertejums
FROM Trase T
LEFT JOIN TrasesAtsauksme TA ON T.Trase_ID = TA.TraseID
GROUP BY T.Trase_ID, T.Nosaukums,T.Grutibas_pakape
ORDER BY Videjais_vertejums DESC;


GO
--Katra lietotāja visus rekordus ar PAR kontekstu un rangu.
CREATE VIEW Lietotaju_Rekordu_Tabula AS SELECT
R.Lietotaja_ID,
R.Trases_ID,
R.Rezultats,
R.Datums,
VW.Trases_PAR,
(R.Rezultats - VW.Trases_PAR) AS Starpiba,
ROW_NUMBER() OVER (PARTITION BY R.Lietotaja_ID ORDER BY (R.Rezultats - VW.Trases_PAR) ASC) AS Pozicija
FROM Rekords R
JOIN vw_Trases_PAR VW ON R.Trases_ID = VW.Trase_ID;

GO
--4.Katra lietotāja personīgais labākais rezultāts
SELECT
L.Lietotajvards,
L.Pieredze,
T.Nosaukums AS Labaka_Trase,
RT.Trases_PAR,
RT.Rezultats AS Labakais_Rezultats,
CASE WHEN RT.Starpiba > 0 THEN '+' + CAST (RT.Starpiba AS NVARCHAR(10))
ELSE CAST(RT.Starpiba AS NVARCHAR(10))
END AS Starpiba_Pret_PAR,
RT.Datums
FROM Lietotaju_Rekordu_Tabula RT
JOIN Lietotajs L ON RT.Lietotaja_ID = L.Lietotaja_ID
JOIN Trase T ON RT.Trases_ID = T.Trase_ID
WHERE RT.Pozicija = 1
ORDER BY RT.Starpiba ASC;
GO

--5.Trases ar  bojājumu ziņojumu skaitu
SELECT
T.Nosaukums AS Trase,
T.Grutibas_pakape,
COUNT(BZ.Zinojuma_ID) AS Bojajumu_skaits,
MAX(BZ.Datums) AS Pedejais_zinojums
FROM Trase T
LEFT JOIN BojajumaZinojums BZ ON T.Trase_ID = BZ.Trases_ID
GROUP BY T.Trase_ID, T.Nosaukums, T.Grutibas_pakape
ORDER BY Bojajumu_skaits DESC;
GO

--6.Draudzības statusa kopsavilkums
SELECT
Statuss,
COUNT(*) AS Skaits
FROM Draudziba
GROUP BY Statuss
ORDER BY Skaits DESC;
GO

--6b.Cik katram draugi un cik daudz spēlējis
SELECT
L.Lietotajvards,
L.Pieredze,
COUNT(DISTINCT CASE 
WHEN D.Lietotajs1_ID = L.Lietotaja_ID THEN D.Lietotajs2_ID 
ELSE D.Lietotajs1_ID 
END) AS Draugu_skaits,
COUNT(DISTINCT RS.Raunda_ID) AS Kopejie_raundi
FROM Lietotajs L
LEFT JOIN Draudziba D ON (L.Lietotaja_ID = D.Lietotajs1_ID OR L.Lietotaja_ID = D.Lietotajs2_ID) AND D.Statuss = 'Apstiprināts'
LEFT JOIN Raunda_Speletajs RS ON L.Lietotaja_ID = RS.Lietotaja_ID
GROUP BY L.Lietotaja_ID, L.Lietotajvards, L.Pieredze
ORDER BY Draugu_skaits DESC;
GO
--7.Lietotāju diska kolekcijas apkopojums
SELECT
L.Lietotajvards,
COUNT(DISTINCT LD.Disks_ID) AS Dazadu_disku_skaits,
SUM(LD.Daudzums) AS Kopejais_disku_daudzums,
STRING_AGG(D.Tips, ', ') AS Disku_tipi
FROM Lietotajs L
JOIN LietotajaDisks LD ON L.Lietotaja_ID = LD.Lietotaja_ID
JOIN Disks D  ON LD.Disks_ID = D.Disks_ID
GROUP BY L.Lietotaja_ID, L.Lietotajvards
ORDER BY Kopejais_disku_daudzums DESC;
GO
-- 8.Katra lietotāja rezultātu rangs trasē
SELECT
T.Nosaukums AS Trase,
L.Lietotajvards,
VW.Trases_PAR,
R.Rezultats,
CASE WHEN (R.Rezultats - VW.Trases_PAR) > 0 THEN '+' + CAST((R.Rezultats - VW.Trases_PAR) AS NVARCHAR(10))
ELSE CAST((R.Rezultats - VW.Trases_PAR) AS NVARCHAR(10))
END AS Starpiba_Pret_PAR,
R.Datums,
DENSE_RANK() OVER (PARTITION BY R.Trases_ID ORDER BY R.Rezultats ASC) AS Rangs_Trase
FROM Rekords R
JOIN Lietotajs L ON R.Lietotaja_ID = L.Lietotaja_ID
JOIN Trase T ON R.Trases_ID = T.Trase_ID
JOIN vw_Trases_PAR VW ON T.Trase_ID = VW.Trase_ID
ORDER BY T.Nosaukums, Rangs_Trase;
GO
--9.Raundus skaits pa mēnešiem katrai trasei
SELECT
T.Nosaukums AS Trase,
FORMAT(R.Datums, 'yyyy-MM') AS Menesis,
COUNT(R.Raunda_ID) AS Raundi_menesi,
SUM(COUNT(R.Raunda_ID)) OVER (
PARTITION BY R.Trases_ID
ORDER BY FORMAT(R.Datums, 'yyyy-MM')
ROWS UNBOUNDED PRECEDING
) AS Raundu_skaits
FROM Raunds R
JOIN Trase T ON R.Trases_ID = T.Trase_ID
WHERE R.IrPabeigts = 1
GROUP BY R.Trases_ID, T.Nosaukums, FORMAT(R.Datums, 'yyyy-MM')
ORDER BY T.Nosaukums, Menesis;
GO
--10.Tūrisma objekti ar to trašu sarakst
SELECT
TO2.Nosaukums AS Turisma_objekts,
TO2.GPS,
T.Nosaukums AS Trase,
TOB.Attalums AS Attalums_km,
TOB.Transports
FROM Turisma_Objekts TO2
JOIN Trases_objekts TOB ON TO2.Objekts_ID = TOB.Objekta_ID
JOIN Trase T ON TOB.Trases_ID  = T.Trase_ID
ORDER BY TO2.Nosaukums, TOB.Attalums;
GO
-- 11. Aktīvākie spēlētāji kuri ir piedalījušies
SELECT
L.Lietotajvards,
L.Pieredze,
COUNT(DISTINCT Ra.Trases_ID) AS Dazadas_trases,
COUNT(RS.Raunda_ID) AS Kopejie_raundi
FROM Lietotajs L
JOIN Raunda_Speletajs RS ON L.Lietotaja_ID = RS.Lietotaja_ID
JOIN Raunds Ra ON RS.Raunda_ID   = Ra.Raunda_ID
GROUP BY L.Lietotaja_ID, L.Lietotajvards, L.Pieredze
HAVING COUNT(RS.Raunda_ID) >= 2
ORDER BY Kopejie_raundi DESC, Dazadas_trases DESC;
GO
-- 12. Laikapstākļu ietekme uz trasēm ar augstu vērtējumu
SELECT
T.Nosaukums AS Trase,
T.Grutibas_pakape,
COUNT(LA.Ieraksts_ID) AS Merij_skaits,
CAST(AVG(CAST(LA.Ietekmes_vertejums AS DECIMAL(4,2))) AS DECIMAL(4,2)) AS Vid_ietekme,
CAST(AVG(LA.Nokrisni) AS DECIMAL(4,2)) AS Vid_nokrisni,
CAST(AVG(LA.Veja_atrums) AS DECIMAL(4,2)) AS Vid_vejs
FROM Trase T
JOIN Laikapstakli LA ON T.Trase_ID = LA.Trases_ID
GROUP BY T.Trase_ID, T.Nosaukums, T.Grutibas_pakape
HAVING AVG(CAST(LA.Ietekmes_vertejums AS DECIMAL(4,2))) > 1.5
ORDER BY Vid_ietekme DESC;
GO
-- 13.Raunda detalizēts rezultāts. visi metienu rezultāti raundā ar PAR starpību un kopējo PAR starpību
SELECT
L.Lietotajvards,
Ra.Raunda_ID,
T.Nosaukums AS Trase,
Ra.Datums,
G.Kartas_nr,
G.PAR_vertiba,
 MR.Metienu_skaits,
CASE
WHEN MR.IrIzlaists = 1 THEN 'Izlaists'
ELSE CAST(MR.Metienu_skaits - G.PAR_vertiba AS NVARCHAR(10))
END AS PAR_starpiba,
SUM(
CASE WHEN MR.IrIzlaists = 0
 THEN MR.Metienu_skaits - G.PAR_vertiba
ELSE 0 END
)OVER(
PARTITION BY MR.Raunda_ID, MR.Lietotaja_ID
ORDER BY G.Kartas_nr
ROWS UNBOUNDED PRECEDING
)AS Rezultats
FROM Metienu_Rezultats MR
JOIN Grozs G ON MR.Groza_ID = G.Groza_ID
JOIN Raunds Ra ON MR.Raunda_ID = Ra.Raunda_ID
JOIN Trase T ON Ra.Trases_ID = T.Trase_ID
JOIN Lietotajs L ON MR.Lietotaja_ID =  L.Lietotaja_ID
ORDER BY Ra.Raunda_ID, G.Kartas_nr;
GO

-- 14. Katra groza vidējais metienu skaits
SELECT 
T.Nosaukums AS Trase,
G.Kartas_nr AS Groza_Numurs,
G.PAR_vertiba AS Groza_PAR,
ISNULL(CAST(AVG(CAST(MR.Metienu_skaits AS DECIMAL(4,2))) AS DECIMAL(4,2)), 0.00) AS Videjais_Metienu_Skaits
FROM Grozs G
JOIN Trase T ON G.Trases_ID = T.Trase_ID
LEFT JOIN Metienu_Rezultats MR ON G.Groza_ID = MR.Groza_ID AND MR.IrIzlaists = 0
GROUP BY T.Trase_ID, T.Nosaukums, G.Groza_ID, G.Kartas_nr, G.PAR_vertiba
ORDER BY T.Nosaukums ASC, G.Kartas_nr ASC;
GO

--15.Raunda noslēguma rezultātu tabula
SELECT
Ra.Raunda_ID,
T.Nosaukums AS Trase,
VW.Trases_PAR,
Ra.Datums,
L.Lietotajvards,
SUM(CASE WHEN MR.IrIzlaists = 0 THEN MR.Metienu_skaits ELSE 0 END) AS Kopejie_Metieni,
SUM(CASE WHEN MR.IrIzlaists = 0 THEN MR.Metienu_skaits - G.PAR_vertiba ELSE 0 END) AS Rezultats_Pret_PAR,
DENSE_RANK() OVER (
PARTITION BY Ra.Raunda_ID
ORDER BY SUM(CASE WHEN MR.IrIzlaists = 0 THEN MR.Metienu_skaits - G.PAR_vertiba ELSE 0 END) ASC
) AS Vieta_Raunda
FROM Metienu_Rezultats MR
JOIN Grozs G ON MR.Groza_ID = G.Groza_ID
JOIN Raunds Ra ON MR.Raunda_ID = Ra.Raunda_ID
JOIN Trase T ON Ra.Trases_ID = T.Trase_ID
JOIN Lietotajs L ON MR.Lietotaja_ID = L.Lietotaja_ID
JOIN vw_Trases_PAR VW ON T.Trase_ID = VW.Trase_ID
WHERE Ra.IrPabeigts = 1
GROUP BY Ra.Raunda_ID, T.Nosaukums, VW.Trases_PAR,Ra.Datums, MR.Lietotaja_ID, L.Lietotajvards
ORDER BY Ra.Raunda_ID, Vieta_Raunda;


-- 16.epastu saraksts
SELECT Epasts, 'Lietotājs' AS Tips FROM Lietotajs
UNION
SELECT L.Epasts, 'Apsaimniekotājs' AS Tips 
FROM Apsaimniekotajs A 
JOIN Lietotajs L ON A.Lietotaja_ID = L.Lietotaja_ID;
GO

