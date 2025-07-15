## INSERCIÓN DE DATOS ENTREGA 2 ##

#Tabla 'plan'
INSERT INTO plan(id_plan,nombre_plan)
VALUES (NULL,"basic"),(NULL,"lite"),(NULL,"full");

SELECT * FROM plan;

#Tabla 'pais'
INSERT INTO pais(id_pais,nombre_pais,moneda)
VALUES (NULL,"Chile","CLP"),(NULL,"Argentina","USD");

SELECT * FROM pais;

#Tabla 'usuario'
INSERT INTO usuario(id_usuario,nombre,apellido,rut,correo,fk_id_pais,fk_id_plan,nombre_plan)
VALUES(NULL,"Nicolás","Vera","202994520","nicolas.vera.gonz@gmail.com",1,1,"basic"),
	(NULL,"Nigulashi","Vera","123456789","xuexiao@gmail.com",2,2,"lite"),
	(NULL,"Camilo","Gonzalez","987654321","camilo.gonzalez@gmail.com",1,3,"full");

SELECT * FROM usuario;

#Tabla 'precio'
INSERT INTO precio(id_precio,fk_id_plan,fk_id_pais,precio)
VALUES  (NULL,1,1,25000),
		(NULL,2,1,50000),
        (NULL,3,1,100000),
        (NULL,1,2,30),
        (NULL,2,2,60),
        (NULL,3,2,120);

SELECT * FROM precio;

#Tabla 'pago'

INSERT INTO pago(id_pago,fk_id_usuario,fk_id_precio,precio,fecha_pago)
	VALUES(NULL,1,1,25000,'2025-07-12'),
          (NULL,1,1,25000,'2025-07-13'),
		  (NULL,2,3,120,'2025-07-13'),
          (NULL,3,5,50000,'2025-07-14');

SELECT * from pago;




# Tabla 'log_error_pago' activando el trigger creado en el script 'entrega_2'
 
 INSERT INTO pago(id_pago,fk_id_usuario,fk_id_precio,precio,fecha_pago)
 VALUES (NULL,1,1,99000,'2025-07-12');

SELECT * FROM log_error_pago;
 



