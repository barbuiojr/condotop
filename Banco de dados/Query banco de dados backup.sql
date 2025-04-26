create database condotop_novo;

use condotop_novo;

create table acessos (
id int  primary key auto_increment not null unique,
id_morador int,
id_condominio int,
tipo_servico varchar(20),
veiculo varchar(20),
placa varchar(9),
entrada_ok bool,
data_autorizacao date,
hora_autorizacao time,
data_entrada date,
hora_entrada time
);

create table usuario (
id int  primary key auto_increment not null unique,
id_condominio int,
portaria varchar(15),
usuario varchar(20),
senha varchar(20),
ativo bool
);

create table moradores (
id int  primary key auto_increment not null unique,
nome varchar(50),
email varchar(40),
proprietario bool,
cpf varchar(14),
telefone varchar(20),
bloco varchar(4),
uh varchar(8),
id_condominio int,
usuario varchar(20),
senha varchar(20)
);

create table condominios(
id int  primary key auto_increment not null unique,
condominio varchar(50),
cnpj varchar(18),
endereco varchar(50),
sindico varchar(50),
telefone varchar(20),
administradora varchar(30),
resp_adm varchar(50),
ativo bool
);

create table visitantes(
id int  primary key auto_increment not null unique,
nome varchar(50),
id_condominio int,
id_morador int,
qrcode varchar(50),
data_entrada date,
hora_entrada time,
validade bool
);

INSERT INTO moradores (
  nome, email, proprietario, cpf, telefone, bloco, uh, id_condominio, usuario, senha
)
VALUES
('Ana Souza', 'ana01@email.com', 1, '12345678901', '1198765432', 'A', '101', 1, '', ''),
('Bruno Lima', 'bruno@email.com', 0, '23456789012', '2191234567', 'B', '250', 2, '', ''),
('Carla Menezes', 'carla@email.com', 1, '34567890123', '3198765432', 'C', '875', 3, '', ''),
('Daniel Rocha', 'daniel@email.com', 0, '45678901234', '4196543210', 'D', '460', 4, '', ''),
('Eduarda Ramos', 'eduarda@email.com', 1, '56789012345', '5193456789', 'E', '320', 5, '', ''),
('Felipe Duarte', 'felipe@email.com', 0, '67890123456', '6198761234', 'F', '998', 1, '', ''),
('Giselle Lima', 'giselle@email.com', 1, '78901234567', '7197654321', 'G', '789', 2, '', ''),
('Henrique Prado', 'henrique@email.com', 0, '89012345678', '8196543212', 'H', '302', 3, '', ''),
('Isabela Teixeira', 'isabela@email.com', 1, '90123456789', '2198765431', 'I', '670', 4, '', ''),
('João Almeida', 'joao@email.com', 0, '01234567890', '1191239876', 'J', '102', 5, '', ''),
('Karina Silveira', 'karina@email.com', 1, '22334455667', '2198877665', 'K', '833', 1, '', ''),
('Leonardo Souza', 'leonardo@email.com', 0, '33445566778', '3194432211', 'L', '411', 2, '', ''),
('Marina Lopes', 'marina@email.com', 1, '44556677889', '4193322110', 'M', '199', 3, '', ''),
('Nathan Viana', 'nathan@email.com', 1, '55667788990', '5199988776', 'A', '120', 4, '', ''),
('Olivia Castro', 'olivia@email.com', 0, '66778899001', '6198765432', 'B', '450', 5, '', ''),
('Paulo Nunes', 'paulo@email.com', 1, '77889900112', '7199998887', 'C', '801', 1, '', ''),
('Quésia Braga', 'quesia@email.com', 0, '88990011223', '8198877665', 'D', '111', 2, '', ''),
('Rafael Costa', 'rafael@email.com', 1, '99001122334', '2197766554', 'E', '220', 3, '', ''),
('Sandra Moraes', 'sandra@email.com', 0, '10111213141', '3196655443', 'F', '345', 4, '', ''),
('Tiago Brito', 'tiago@email.com', 1, '21222324354', '4195544332', 'G', '999', 5, '', ''),
('Úrsula Mendes', 'ursula@email.com', 0, '32333435465', '5194433221', 'H', '654', 1, '', ''),
('Victor Hugo', 'victor@email.com', 1, '43444546576', '6193322110', 'I', '567', 2, '', ''),
('Wesley Barros', 'wesley@email.com', 0, '54555657687', '7192211009', 'J', '129', 3, '', ''),
('Xuxa Lima', 'xuxa@email.com', 1, '65666768798', '8191100998', 'K', '888', 4, '', ''),
('Yasmin Cunha', 'yasmin@email.com', 0, '76777879809', '2190099887', 'L', '543', 5, '', ''),
('Zeca Pagodinho', 'zeca@email.com', 1, '87888980910', '3199988776', 'M', '1000', 1, '', ''),
('Aline Alves', 'aline@email.com', 0, '98999090121', '4198877665', 'A', '201', 2, '', ''),
('Bruna Silva', 'bruna@email.com', 1, '12312312300', '5197766554', 'B', '621', 3, '', ''),
('Caio Oliveira', 'caio@email.com', 0, '23423423411', '6196655443', 'C', '930', 4, '', ''),
('Diana Freitas', 'diana@email.com', 1, '34534534522', '7195544332', 'D', '302', 5, '', ''),
('Erick Torres', 'erick@email.com', 0, '45645645633', '8194433221', 'E', '128', 1, '', ''),
('Fabiana Rocha', 'fabiana@email.com', 1, '56756756744', '2193322110', 'F', '789', 2, '', ''),
('Gustavo Rezende', 'gustavo@email.com', 0, '67867867855', '3192211009', 'G', '901', 3, '', ''),
('Helena Duarte', 'helena@email.com', 1, '78978978966', '4191100998', 'H', '370', 4, '', ''),
('Igor Martins', 'igor@email.com', 0, '89089089077', '5190099887', 'I', '222', 5, '', ''),
('Joana Reis', 'joana@email.com', 1, '90190190188', '6199988776', 'J', '143', 1, '', ''),
('Kevin Lopes', 'kevin@email.com', 0, '01201201299', '7198877665', 'K', '666', 2, '', ''),
('Larissa Melo', 'larissa@email.com', 1, '12312312400', '8197766554', 'L', '753', 3, '', ''),
('Matheus Cruz', 'matheus@email.com', 0, '23423423511', '2196655443', 'M', '310', 4, '', ''),
('Nayara Santos', 'nayara@email.com', 1, '34534534622', '3195544332', 'A', '450', 5, '', ''),
('Otávio Neves', 'otavio@email.com', 0, '45645645733', '4194433221', 'B', '999', 1, '', ''),
('Priscila Xavier', 'priscila@email.com', 1, '56756756844', '5193322110', 'C', '777', 2, '', ''),
('Ramon Peixoto', 'ramon@email.com', 0, '67867867955', '6192211009', 'D', '312', 3, '', ''),
('Sofia Luz', 'sofia@email.com', 1, '78978979066', '7191100998', 'E', '189', 4, '', ''),
('Thales Castro', 'thales@email.com', 0, '89089089177', '8190099887', 'F', '234', 5, '', ''),
('Vera Souza', 'vera@email.com', 1, '90190190288', '2199988776', 'G', '987', 1, '', ''),
('Wellington Dias', 'wellington@email.com', 0, '01201201399', '3198877665', 'H', '313', 2, '', ''),
('Zilda Alves', 'zilda@email.com', 1, '12312312500', '4197766554', 'I', '678', 3, '', '');

INSERT INTO acessos (
  id_morador, id_condominio, tipo_servico, veiculo, placa, entrada_ok,
  data_autorizacao, hora_autorizacao, data_entrada, hora_entrada
)
VALUES
(12, 3, 'Uber', 'Toyota Corolla', 'ABC1D23', 1, '2025-04-10', '08:12:00', NULL, NULL),
(5, 2, 'Prestador', 'Fiat Uno', 'DEF2G45', 1, '2025-04-10', '09:45:00', NULL, NULL),
(27, 1, 'Uber', 'Renault Kwid', 'GHI3H67', 1, '2025-04-10', '10:33:00', NULL, NULL),
(40, 4, 'Prestador', 'Volkswagen Fox', 'JKL4J89', 1, '2025-04-10', '11:05:00', NULL, NULL),
(15, 5, 'Uber', 'Hyundai HB20', 'MNO5K12', 1, '2025-04-10', '07:22:00', NULL, NULL),
(9, 1, 'Prestador', 'Chevrolet Onix', 'PQR6L34', 1, '2025-04-10', '08:40:00', NULL, NULL),
(31, 3, 'Uber', 'Nissan Kicks', 'STU7M56', 1, '2025-04-10', '12:15:00', NULL, NULL),
(22, 2, 'Prestador', 'Fiat Toro', 'VWX8N78', 1, '2025-04-10', '13:05:00', NULL, NULL),
(4, 4, 'Uber', 'Peugeot 208', 'YZA9P90', 1, '2025-04-10', '14:45:00', NULL, NULL),
(48, 5, 'Prestador', 'Ford Ka', 'BCD1R11', 1, '2025-04-10', '15:12:00', NULL, NULL),
(18, 1, 'Uber', 'Honda Fit', 'EFG2S22', 1, '2025-04-10', '16:40:00', NULL, NULL),
(33, 2, 'Prestador', 'Citroën C3', 'HIJ3T33', 1, '2025-04-10', '17:30:00', NULL, NULL),
(26, 3, 'Uber', 'Volkswagen Polo', 'KLM4U44', 1, '2025-04-10', '18:55:00', NULL, NULL),
(8, 4, 'Prestador', 'Fiat Argo', 'NOP5V55', 1, '2025-04-10', '19:20:00', NULL, NULL),
(35, 5, 'Uber', 'Renault Logan', 'QRS6W66', 1, '2025-04-10', '20:10:00', NULL, NULL),
(13, 2, 'Prestador', 'Hyundai Creta', 'TUV7X77', 1, '2025-04-10', '21:00:00', NULL, NULL),
(6, 1, 'Uber', 'Chevrolet Spin', 'WXY8Y88', 1, '2025-04-10', '22:15:00', NULL, NULL),
(24, 3, 'Prestador', 'Honda Civic', 'ZAB9Z99', 1, '2025-04-10', '23:45:00', NULL, NULL),
(10, 4, 'Uber', 'Toyota Yaris', 'CDE1A01', 1, '2025-04-10', '06:25:00', NULL, NULL),
(44, 5, 'Prestador', 'Ford Ecosport', 'FGH2B02', 1, '2025-04-10', '07:00:00', NULL, NULL),
(3, 1, 'Uber', 'Volkswagen Gol', 'IJK3C03', 1, '2025-04-10', '08:30:00', NULL, NULL),
(36, 2, 'Prestador', 'Nissan Versa', 'LMN4D04', 1, '2025-04-10', '09:15:00', NULL, NULL),
(17, 3, 'Uber', 'Fiat Mobi', 'OPQ5E05', 1, '2025-04-10', '10:00:00', NULL, NULL),
(50, 4, 'Prestador', 'Chevrolet Celta', 'RST6F06', 1, '2025-04-10', '11:45:00', NULL, NULL),
(2, 5, 'Uber', 'Honda WR-V', 'UVW7G07', 1, '2025-04-10', '12:50:00', NULL, NULL),
(28, 1, 'Prestador', 'Peugeot 2008', 'XYZ8H08', 1, '2025-04-10', '13:40:00', NULL, NULL),
(19, 2, 'Uber', 'Hyundai Tucson', 'ABC9I09', 1, '2025-04-10', '14:30:00', NULL, NULL),
(7, 3, 'Prestador', 'Ford Ranger', 'DEF1J10', 1, '2025-04-10', '15:55:00', NULL, NULL),
(41, 4, 'Uber', 'Chevrolet Tracker', 'GHI2K11', 1, '2025-04-10', '16:20:00', NULL, NULL),
(20, 5, 'Prestador', 'Toyota Hilux', 'JKL3L12', 1, '2025-04-10', '17:40:00', NULL, NULL);

ALTER TABLE acessos
ADD COLUMN validade BOOLEAN;

select * from moradores;
select * from acessos;
select * from visitantes;
SELECT tipo_servico, veiculo, placa, entrada_ok, data_autorizacao, hora_autorizacao, data_entrada, hora_entrada, moradores.uh, moradores.nome FROM acessos
INNER JOIN moradores ON id_morador = moradores.id WHERE entrada_ok=0;
SELECT acessos.id, tipo_servico, veiculo, placa, entrada_ok, data_autorizacao,
        hora_autorizacao, data_entrada, hora_entrada, moradores.uh, moradores.nome FROM acessos
        INNER JOIN moradores ON id_morador = moradores.id WHERE entrada_ok = 1 AND validade = 1;
SELECT visitantes.id, visitantes.nome as 'Visitante', visitantes.id_condominio, id_morador, qrcode, data_entrada, validade,
moradores.nome, moradores.uh FROM visitantes
INNER JOIN moradores on id_morador = moradores.id WHERE validade = 1;