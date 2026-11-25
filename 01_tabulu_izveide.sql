CREATE TABLE Lietotajs(
Lietotaja_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Epasts NVARCHAR(150) NOT NULL UNIQUE,
Parole NVARCHAR(255) NOT NULL,
Lietotajvards NVARCHAR(60) NOT NULL UNIQUE,
Pieredze NVARCHAR(20) NOT NULL DEFAULT 'Iesācējs',
Datums DATE DEFAULT GETDATE(),
CONSTRAINT chk_Pieredze CHECK (Pieredze IN('Iesācējs', 'Amatieris', 'Eksperts'))
);

CREATE TABLE Disks(
Disks_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Nosaukums NVARCHAR(100) NOT NULL,
Razotajs NVARCHAR(100) NOT NULL,
Tips NVARCHAR(30) NOT NULL,
Atrums DECIMAL(3,1) NOT NULL,
Glide INT NOT NULL,
Turn INT NOT NULL,
Fade INT NOT NULL,
CONSTRAINT chk_Disks_Tips  CHECK (Tips IN ('Distance','Fairway','Midrange','Putter')),
CONSTRAINT chk_Disks_Atrums CHECK (Atrums BETWEEN 1.0 AND 14.0),
CONSTRAINT chk_Disks_Glide CHECK (Glide BETWEEN 1 AND 7),
CONSTRAINT chk_Disks_Turn  CHECK (Turn  BETWEEN -5 AND 0),
CONSTRAINT chk_Disks_Fade  CHECK (Fade  BETWEEN 0 AND 5)
);

CREATE TABLE Turisma_Objekts(
Objekts_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Nosaukums NVARCHAR(150) NOT NULL,
Apraksts NVARCHAR(MAX) NULL,
GPS NVARCHAR(60) NOT NULL
);

CREATE TABLE Apsaimniekotajs(
Apsaimniekotajs_ID INT NOT NULL IDENTITY (1,1) PRIMARY KEY,
Lietotaja_ID INT NOT NULL UNIQUE,
Datums DATE DEFAULT GETDATE(),
CONSTRAINT FK_Apsaimniekotajs_Lietotajs FOREIGN KEY (Lietotaja_ID) REFERENCES Lietotajs(Lietotaja_ID)
);

CREATE TABLE Trase(
Trase_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Apsaimniekotajs_ID INT NOT NULL,
Nosaukums NVARCHAR(150) NOT NULL,
Adrese NVARCHAR(255) NOT NULL,
GPS NVARCHAR(60) NOT NULL,
Apraksts NVARCHAR(MAX) NULL,
Grozu_skaits INT NOT NULL,
Grutibas_pakape NVARCHAR(20) NOT NULL,
Izveidota DATE NOT NULL,
CONSTRAINT FK_Trase_Apsaimnieko FOREIGN KEY (Apsaimniekotajs_ID) REFERENCES Apsaimniekotajs(Apsaimniekotajs_ID),
CONSTRAINT chk_Trase_Pakape CHECK (Grutibas_pakape IN ('Iesācējs','Amatieris','Eksperts')),
CONSTRAINT chk_Trase_Grozi CHECK (Grozu_skaits > 0)
);

CREATE TABLE Grozs(
Groza_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Trases_ID INT NOT NULL,
Kartas_nr INT NOT NULL,
Distance INT NOT NULL,
PAR_vertiba INT NOT NULL,
Groza_GPS NVARCHAR(60) NULL,
CONSTRAINT FK_Grozs_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase(Trase_ID),
CONSTRAINT chk_Grozs_PAR CHECK (PAR_vertiba BETWEEN 2 AND 6),
CONSTRAINT chk_Grozs_Dist CHECK (Distance > 0)
);

CREATE TABLE Raunds (
Raunda_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Trases_ID INT NOT NULL,
Datums DATETIME DEFAULT GETDATE(),
IrPabeigts BIT NOT NULL DEFAULT 0,
CONSTRAINT FK_Raunds_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase(Trase_ID)
);

CREATE TABLE TrasesAtsauksme (
Atsauksmes_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
LietotajsID INT NOT NULL,
TraseID INT NOT NULL,
Teksts NVARCHAR(MAX) NULL,
Vertejums INT NOT NULL,
Datums DATE DEFAULT GETDATE(),
CONSTRAINT FK_Atsauksme_Lietotajs FOREIGN KEY (LietotajsID) REFERENCES Lietotajs(Lietotaja_ID),
CONSTRAINT FK_Atsauksme_Trase FOREIGN KEY (TraseID) REFERENCES Trase(Trase_ID),
CONSTRAINT chk_Vertejums CHECK (Vertejums BETWEEN 1 AND 5)
);

CREATE TABLE Rekords (
Rekorda_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Lietotaja_ID INT NOT NULL,
Trases_ID INT NOT NULL,
Datums DATE DEFAULT GETDATE(),
Rezultats INT NOT NULL,
CONSTRAINT FK_Rekords_Lietotajs FOREIGN KEY (Lietotaja_ID) REFERENCES Lietotajs(Lietotaja_ID),
CONSTRAINT FK_Rekords_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase(Trase_ID)
);

CREATE TABLE BojajumaZinojums (
Zinojuma_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Lietotaja_ID INT NOT NULL,
Trases_ID INT NOT NULL,
Datums DATETIME DEFAULT GETDATE(),
Apraksts NVARCHAR(MAX) NOT NULL,
CONSTRAINT FK_Zinojums_Lietotajs FOREIGN KEY (Lietotaja_ID) REFERENCES Lietotajs(Lietotaja_ID),
CONSTRAINT FK_Zinojums_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase(Trase_ID)
);

CREATE TABLE Trases_zinojums (
T_Zinojuma_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Trases_ID INT NOT NULL,
Apsaimniekotajs_ID INT NOT NULL,
Apraksts NVARCHAR(MAX) NULL,
Statuss NVARCHAR(80) NOT NULL,
Datums_no DATE NOT NULL,
Datums_lidz DATE NULL,
CONSTRAINT FK_TZinojums_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase(Trase_ID),
CONSTRAINT FK_TZzinojums_Apsaimniekotajs FOREIGN KEY (Apsaimniekotajs_ID) REFERENCES Apsaimniekotajs(Apsaimniekotajs_ID)
);

CREATE TABLE Trases_objekts (
Objekta_ID INT NOT NULL,
Trases_ID INT NOT NULL,
Attalums DECIMAL(8,2) NULL,
Transports NVARCHAR(100) NULL,
CONSTRAINT PK_TrasesObjekts PRIMARY KEY (Objekta_ID, Trases_ID),
CONSTRAINT FK_TObjekts_Objekts FOREIGN KEY (Objekta_ID) REFERENCES Turisma_Objekts (Objekts_ID),
CONSTRAINT FK_TObjekts_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase (Trase_ID)
);

CREATE TABLE Laikapstakli (
Ieraksts_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Trases_ID INT NOT NULL,
Temperatura DECIMAL(4,1) NOT NULL,
Veja_atrums DECIMAL(5,2) NOT NULL,
Nokrisni DECIMAL(5,2) NOT NULL,
Ietekmes_vertejums INT NOT NULL,
CONSTRAINT FK_Laikapstakli_Trase FOREIGN KEY (Trases_ID) REFERENCES Trase(Trase_ID),
CONSTRAINT chk_Laikapstaklu_Ietekme CHECK (Ietekmes_vertejums BETWEEN 0 AND 5)
);

CREATE TABLE Draudziba (
Lietotajs1_ID INT NOT NULL,
Lietotajs2_ID INT NOT NULL,
Datums DATE DEFAULT GETDATE (),
Statuss NVARCHAR(20) NOT NULL DEFAULT 'Gaida',
CONSTRAINT PK_Draudziba PRIMARY KEY (Lietotajs1_ID, Lietotajs2_ID),
CONSTRAINT FK_Draudziba_L1 FOREIGN KEY (Lietotajs1_ID) REFERENCES Lietotajs(Lietotaja_ID),
CONSTRAINT FK_Draudziba_L2 FOREIGN KEY (Lietotajs2_ID) REFERENCES Lietotajs(Lietotaja_ID),
CONSTRAINT chk_Draudziba_Statuss CHECK (Statuss IN ('Gaida','Apstiprināts','Noraidīts')),
CONSTRAINT chk_Draudziba_Diff CHECK (Lietotajs1_ID <> Lietotajs2_ID)
);

CREATE TABLE LietotajaDisks (
LietotajaDisks_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Lietotaja_ID INT NOT NULL,
Disks_ID INT NOT NULL,
Krasa NVARCHAR(50) NULL,
Daudzums INT NOT NULL DEFAULT 1,
CONSTRAINT FK_LDisks_Lietotajs FOREIGN KEY (Lietotaja_ID) REFERENCES Lietotajs(Lietotaja_ID),
CONSTRAINT FK_LDisks_Disks FOREIGN KEY (Disks_ID) REFERENCES Disks (Disks_ID),
CONSTRAINT chk_LDisks_Daudzums CHECK (Daudzums >= 1)
);

CREATE TABLE Raunda_Speletajs (
Raunda_ID INT NOT NULL,
Lietotaja_ID INT NOT NULL,
IrLideris BIT NOT NULL DEFAULT 0,
CONSTRAINT PK_RaundaSpeletajs PRIMARY KEY (Raunda_ID, Lietotaja_ID),
CONSTRAINT FK_RSpeletajs_Raunds FOREIGN KEY (Raunda_ID) REFERENCES Raunds(Raunda_ID),
CONSTRAINT FK_RSpeletajs_Lietotajs FOREIGN KEY (Lietotaja_ID) REFERENCES Lietotajs(Lietotaja_ID)
);

CREATE TABLE Metienu_Rezultats (
Rezultata_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
Raunda_ID INT NOT NULL,
Lietotaja_ID INT NOT NULL,
Groza_ID INT NOT NULL,
Metienu_skaits INT NULL,
IrIzlaists BIT NOT NULL DEFAULT 0,
CONSTRAINT FK_Rez_Raunda_Spel FOREIGN KEY (Raunda_ID, Lietotaja_ID) REFERENCES Raunda_Speletajs(Raunda_ID, Lietotaja_ID),
CONSTRAINT FK_Rez_Grozs FOREIGN KEY (Groza_ID) REFERENCES Grozs(Groza_ID),
CONSTRAINT chk_Rez_Metienu CHECK (Metienu_skaits IS NULL OR Metienu_skaits >= 1)
);
