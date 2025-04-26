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