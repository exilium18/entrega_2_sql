-- ENTREGA 2 CURSO CODERHOUSE SQL
-- Estudiante: Nicolás Vera
-- Consignia: 81855

### PRIMERA PARTE - CÓDIGO ENTREGA 1 MODIFICADO ###

## Según lo indicado la entrega anterior, crearé un schema que recopile información sobre una plataforma educativa para estudiantes escolares. 
## En esta serán capaces de comprar distintos tipos de planes, los cuales cada uno aplican una cantidad de beneficios que se consumen al momento de comprarlos (es decir, no tienen una duración específica). 

## Correcciones entrega 1:
## 1. Se cambian los nombres de las tablas a singular ("usuarios -> "usuario", "precios" -> "precio", etc). 
## 2. Se realizó FK única y exclusivamente referenciando a Primary Keys. Adicionalmente, se agrega al inicio del nombre de la variable las letras "fk_" en caso de ser una Foreign Key, para facilitar la identificación del mismo.


DROP SCHEMA IF EXISTS entrega_2;
CREATE SCHEMA entrega_2;
USE entrega_2;


## Tabla  - Planes de estudio 
# Nombre de la tabla: "plan"
CREATE TABLE IF NOT EXISTS plan(
id_plan INT PRIMARY KEY AUTO_INCREMENT,
nombre_plan VARCHAR(20) UNIQUE 
);


##Tabla  - País y Moneda de origen
# nombre de la tabla: pais
CREATE TABLE IF NOT EXISTS pais(
id_pais INT PRIMARY KEY AUTO_INCREMENT,
nombre_pais VARCHAR(30) UNIQUE NOT NULL,
moneda VARCHAR(5) UNIQUE NOT NULL
);


## Tabla - Estudiantes de la plataforma
# Nombre de la tabla: "usuario"
CREATE TABLE IF NOT EXISTS usuario(
id_usuario INT PRIMARY KEY AUTO_INCREMENT,
nombre VARCHAR(30),
apellido VARCHAR(30),
rut INT NOT NULL,
correo VARCHAR(50) NOT NULL UNIQUE, 
fk_id_plan INT,
fk_id_pais INT,
nombre_plan VARCHAR(20), 
FOREIGN KEY (fk_id_plan) REFERENCES plan(id_plan),
FOREIGN KEY (fk_id_pais) REFERENCES pais(id_pais)
);


## Tabla  - Precios de los planes
# Nombre de la tabla: "precio"
CREATE TABLE IF NOT EXISTS precio(
id_precio INT PRIMARY KEY AUTO_INCREMENT,
fk_id_plan INT,
fk_id_pais INT, 
precio INT,
FOREIGN KEY (fk_id_plan) REFERENCES plan(id_plan),
FOREIGN KEY (fk_id_pais) REFERENCES pais(id_pais)
);

## Tabla  - Pagos de clientes
# Nombre de la tabla: "pago"

CREATE TABLE IF NOT EXISTS pago(
id_pago INT PRIMARY KEY AUTO_INCREMENT,
fk_id_usuario INT NOT NULL,
fk_id_precio INT NOT NULL,
precio INT NOT NULL, 
fecha_pago DATE DEFAULT (CURRENT_DATE) NOT NULL,

FOREIGN KEY (fk_id_usuario) REFERENCES usuario(id_usuario),
FOREIGN KEY (fk_id_precio) REFERENCES precio(id_precio)
);

## Tabla - Errores de pago

CREATE TABLE log_error_pago(
id_log INT AUTO_INCREMENT PRIMARY KEY,
id_usuario INT,
id_precio INT,
precio_ingresado INT,
precio_correcto INT,
fecha_error DATE DEFAULT (CURRENT_DATE)
);


### SEGUNDA PARTE: VISTAS, FUNCIONES, STORES PROCEDURES, TRIGGERS ###

#VISTAS

## VISTA1: nombre planes y moneda
## Objetivo: Identificar el nombre del plan y moneda asociandolo con la tabla precio
CREATE VIEW detalle_planes AS
SELECT precio.id_precio,
	   plan.nombre_plan,
       pais.moneda
FROM precio
       LEFT JOIN pais ON precio.fk_id_pais = pais.id_pais
       LEFT JOIN plan ON precio.fk_id_plan = plan.id_plan;     
       

########### VISTAS ########### 
# Descripción detallada: Detalle de las ventas realizadas agrupadas según el id_precio. Se ocupa esta variable debido a las diferencias de montos en moneda (USD, CLP, COP). 
# Objetivo: Ver cual fue el producto que más se vendió en el día actual, para así tomar decisiones para el día siguiente. 
# Tablas: 'pago'.

CREATE VIEW ventas_historicas_por_plan AS
SELECT p.id_precio, d.nombre_plan, d.moneda, p.ventas, p.fecha_pago FROM (SELECT 
  subconsulta.id_precio,
  subconsulta.fecha_pago,
  IFNULL(SUM(pago.precio), 0) AS ventas
FROM 
  (SELECT 
      p.id_precio,
      f.fecha_pago
   FROM 
     (SELECT DISTINCT fecha_pago FROM pago WHERE fecha_pago IS NOT NULL) f
   CROSS JOIN 
     (SELECT id_precio FROM precio) p
  ) AS subconsulta
LEFT JOIN pago ON subconsulta.id_precio = pago.fk_id_precio AND subconsulta.fecha_pago = pago.fecha_pago
GROUP BY subconsulta.id_precio, subconsulta.fecha_pago
ORDER BY subconsulta.fecha_pago, subconsulta.id_precio) p
LEFT JOIN detalle_planes d ON p.id_precio = d.id_precio;


SELECT * from ventas_historicas_por_plan; 

########### FUNCIONES ###########
## EN ESTA ENTREGA, CREARÉ UNA FUNCIÓN QUE ME PERMITA IDENTIFICAR EL NOMBRE COMPLETO DE UN USUARIO INGRESANDO SU NÚMERO DE IDENTIFICACIÓN (RUT)

DELIMITER //

CREATE FUNCTION obtener_nombre(rut_funcion INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
	DECLARE nombre_completo VARCHAR(100);
    
    SELECT CONCAT(nombre, ' ', apellido)
    INTO nombre_completo
    FROM usuario
    WHERE rut = rut_funcion;
    
IF nombre_completo IS NULL THEN
	RETURN 'Verificador Nacional no Encontrado';
END IF;

RETURN nombre_completo;
END //

SELECT obtener_nombre(202994520);

DELIMITER ;

########### STORE PROCEDURES ###########

## CREAREMOS UN STORE PROCEDURE QUE MUESTRE LA VISTA DE VENTAS EN UN RANGO EN PARTICULAR

DELIMITER //

CREATE PROCEDURE ventas_por_rango(
IN fecha_inicio DATE,
IN fecha_fin DATE,
IN tipo_moneda VARCHAR(5)
)
BEGIN
SELECT * 
FROM ventas_historicas_por_plan
WHERE fecha_pago BETWEEN fecha_inicio AND fecha_fin 
AND (tipo_moneda IS NULL OR moneda = tipo_moneda);

END //

DELIMITER ;

CALL ventas_por_rango ('2025-07-13','2025-07-14',NULL);


########### TRIGGERS ###########

# TRIGGER 1: validacion_precio
# Descripción: Se valida si el precio que está ingresando en la tabla 'pago' coincide con el que está en ese momento en la tabla 'precio'.
# Los precios pueden ir cambiando durante el tiempo, por lo que no se debe hacer una referencia estricta para el registro de pagos históricos. Por lo mismo, lo mejor es validarlo mediante un trigger. 

DELIMITER //

 CREATE TRIGGER validar_precio_pago
 BEFORE INSERT ON pago
 FOR EACH ROW
 BEGIN
	DECLARE precio_actual INT;
    
    SELECT precio INTO precio_actual
    FROM precio
    WHERE id_precio = new.fk_id_precio
    LIMIT 1;
 
 IF new.precio <> precio_actual THEN
 INSERT INTO log_error_pago(id_usuario,id_precio,precio_ingresado,precio_correcto)
 VALUES (new.fk_id_usuario, new.fk_id_precio, new.precio, precio_actual);
 END IF;
 
 END //
 
 DELIMITER ; 
 
 
 
 