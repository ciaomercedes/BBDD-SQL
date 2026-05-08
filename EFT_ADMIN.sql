-- ========================================
---USUARIO ADMIN
---CASO 1: ESTRATEGIA DE USUARIOS
-- ========================================
--CREACION DE USUARIOS
---PRY2205_EFT (OWNER)
CREATE USER PRY2205_EFT
IDENTIFIED BY "Password.PFT99"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON DATA;

GRANT CREATE SESSION TO PRY2205_EFT;

--PRIVILEGIOS DE CONSTRUCCION
GRANT CREATE TABLE TO PRY2205_EFT;
GRANT CREATE VIEW TO PRY2205_EFT;
GRANT CREATE INDEX TO PRY2205_EFT;
GRANT CREATE SEQUENCE TO PRY2205_EFT;
GRANT CREATE SYNONYM TO PRY2205_EFT;
GRANT CREATE PUBLIC SYNONYM TO PRY2205_EFT;

-- ========================================
---PRY2205_EFT_DES
CREATE USER PRY2205_EFT_DES
IDENTIFIED BY "Password.PFT99"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON DATA;

GRANT CREATE SESSION TO PRY2205_EFT_DES;

--PRIVILEGIOS NECESARIOS
GRANT CREATE VIEW TO PRY2205_EFT_DES;
GRANT CREATE SEQUENCE TO PRY2205_EFT_DES;
GRANT CREATE PROCEDURE TO PRY2205_EFT_DES;

GRANT SELECT ON PRY2205_EFT.deudor TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.cuota_tarjetas TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.tarjeta_deudor TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.ocupacion TO PRY2205_EFT_DES;

-- ========================================
---PRY2205_EFT_CON
CREATE USER PRY2205_EFT_CON
IDENTIFIED BY "Password.PFT99"
DEFAULT TABLESPACE DATA
TEMPORARY TABLESPACE TEMP
QUOTA 10M ON DATA;

GRANT CREATE SESSION TO PRY2205_EFT_CON;

-- ========================================
--CREACIÓIN DEL ROLES

CREATE ROLE PRY2205_ROL_D;
-- Privilegios para desarrollador
GRANT SELECT ON PRY2205_EFT.deudor TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.cuota_tarjetas TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.tarjeta_deudor TO PRY2205_ROL_D;
GRANT SELECT ON PRY2205_EFT.ocupacion TO PRY2205_ROL_D;


CREATE ROLE PRY2205_ROL_C;
-- Privilegios para consulta
GRANT SELECT ON PRY2205_EFT.deudor TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.cuota_tarjetas TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.tarjeta_deudor TO PRY2205_ROL_C;
GRANT SELECT ON PRY2205_EFT.ocupacion TO PRY2205_ROL_C;

--ASIGNACIÓN DE ROL
GRANT PRY2205_ROL_D TO PRY2205_EFT_DES;
GRANT PRY2205_ROL_C TO PRY2205_EFT_CON;

-- ===================================================================================================================================
-- ===================================================================================================================================
---CASOS 2 Y 3: CREACIÓN DE INFORME Y OPTIMIZACIÓN DE SENTENCIAS SQL
---USUARIO PRY2205_EFT_DES
-- ===================================================================================================================================
----CREACION DE LA VISTA A VW_ANALISIS_DEUDORES_PERIODO
CREATE OR REPLACE VIEW VW_ANALISIS_DEUDORES_PERIODO AS
SELECT
    REPLACE(TO_CHAR(d.numrun,'99,999,999'),',','.') || '-' || d.dvrun AS "RUT_DEUDOR",
    INITCAP(d.pnombre || ' ' || d.appaterno || ' ' || d.apmaterno) AS "NOMBRE DEUDOR",
    COUNT(DISTINCT ct.nro_cuota) AS "TOTAL_CUOTAS",
    ROUND(AVG(ct.valor_cuota)) AS "PROMEDIO_VALOR_CUOTAS",
    TO_CHAR(MIN(ct.FECHA_VENC_CUOTA), 'DD-MM-YYYY') AS "FECHA_MAS_ANTIGUA",
    NVL(to_char(d.fono_contacto), 'Sin Información') AS "TELEFONO",
    UPPER(o.nombre_prof_ofic) AS "OCUPACION",
    MAX(td.cupo_disp_compra) AS "CUPO_DISP_COMPRA"

FROM PRY2205_EFT.deudor d
INNER JOIN PRY2205_EFT.tarjeta_deudor td  --intersección porque necesito registros que estén en ambas tablas y evitar nulos
    ON d.numrun = td.numrun
INNER JOIN PRY2205_EFT.cuota_tarjetas ct
    ON td.nro_tarjeta = ct.nro_tarjeta
JOIN PRY2205_EFT.ocupacion o  ---solo necesito el dato cuando hay un match con los inner
    ON d.cod_ocupacion = o.cod_ocupacion
    
WHERE d.numrun IN (
    SELECT numrun
    FROM PRY2205_EFT.deudor
    
    MINUS
    
    SELECT numrun
    FROM PRY2205_EFT.deudor
    WHERE cod_ocupacion in (3,8,9)
)
    
AND EXTRACT(YEAR FROM ct.FECHA_VENC_CUOTA) = EXTRACT(YEAR FROM SYSDATE) - 1

GROUP BY
    d.numrun,
    d.dvrun,
    d.pnombre,
    d.appaterno,
    d.apmaterno,
    d.fono_contacto,
    o.nombre_prof_ofic

HAVING ROUND(AVG(ct.valor_cuota)) < (
    SELECT MAX(promedio)
    FROM (
        SELECT AVG(ct2.valor_cuota) AS promedio
        FROM PRY2205_EFT.tarjeta_deudor td2
        JOIN PRY2205_EFT.cuota_tarjetas ct2
            ON td2.nro_tarjeta = ct2.nro_tarjeta
        GROUP BY td2.nro_tarjeta
    )
)

ORDER BY TOTAL_CUOTAS ASC, CUPO_DISP_COMPRA ASC;
commit;

---Otorgar privilegio de acceso al usuario de consulta
GRANT SELECT ON VW_ANALISIS_DEUDORES_PERIODO TO PRY2205_EFT_CON;

-- ===================================================================================================================================
-- USURARIO PRY2205_EFT (OWNER)
-- ===================================================================================================================================
-- Crear sinónimos públicos (para ocultar tablas reales)
CREATE PUBLIC SYNONYM deudor FOR PRY2205_EFT.deudor;
CREATE PUBLIC SYNONYM ocupacion FOR PRY2205_EFT.ocupacion;
CREATE PUBLIC SYNONYM tarjeta_deudor FOR PRY2205_EFT.tarjeta_deudor;
CREATE PUBLIC SYNONYM cuota_tarjetas FOR PRY2205_EFT.cuota_tarjetas;
CREATE PUBLIC SYNONYM trans_tarj_d FOR PRY2205_EFT.transaccion_tarjeta_deudor;
CREATE PUBLIC SYNONYM sucursal FOR PRY2205_EFT.sucursal;

--Privilegios adicionales
GRANT SELECT ON PRY2205_EFT.OCUPACION TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON PRY2205_EFT.DEUDOR TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON PRY2205_EFT.TARJETA_DEUDOR TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON PRY2205_EFT.CUOTA_TARJETAS TO PRY2205_EFT_DES WITH GRANT OPTION;
GRANT SELECT ON PRY2205_EFT.OCUPACION TO PRY2205_EFT_DES WITH GRANT OPTION;

--Creacion de Indices para la vista
--PARA JOIN y filtro WHERE para disminuir full table scans y mejorar el tiempo de respuesta de la vista
CREATE INDEX IDX_TARJETA_DEUDOR_NUMRUN ON PRY2205_EFT.TARJETA_DEUDOR (numrun);
CREATE INDEX IDX_CUOTA_TARJETA_NRO ON PRY2205_EFT.CUOTA_TARJETAS (nro_tarjeta);
CREATE INDEX IDX_DEUDOR_OCUPACION ON PRY2205_EFT.DEUDOR (cod_ocupacion);

---INFORME DETALLADO DEL COMPORTAMIENTO DE LOS DEUDORES (T_ANALISIS_TARJETAS)
INSERT INTO T_ANALISIS_TARJETAS (
    NUM_ANALISIS,
    NRO_TARJETA,
    TOTAL_CUOTAS,
    MONTO_TOTAL_TRANSA,
    FECHA_TRANSACCION,
    DIRECCION,
    MONTO_REAJUSTADO
)
SELECT
    ROW_NUMBER() OVER (ORDER BY NRO_TARJETA, MONTO_TOTAL_TRANSA) AS NUM_ANALISIS,
    NRO_TARJETA,
    TOTAL_CUOTAS,
    MONTO_TOTAL_TRANSA,
    FECHA_TRANSACCION,
    DIRECCION,
    MONTO_REAJUSTADO
FROM (
    SELECT
        ttd.nro_tarjeta AS NRO_TARJETA,
        ttd.total_cuotas_transaccion AS TOTAL_CUOTAS,
        ttd.monto_total_transaccion AS MONTO_TOTAL_TRANSA,
        TO_CHAR(ttd.fecha_transaccion, 'DD/MM/YYYY') AS FECHA_TRANSACCION,
        INITCAP(s.direccion) AS DIRECCION,
        ROUND(ttd.monto_total_transaccion * 1.05) AS MONTO_REAJUSTADO

    FROM trans_tarj_d ttd
    INNER JOIN sucursal s
        ON ttd.id_sucursal = s.id_sucursal
    WHERE UPPER(s.direccion) LIKE 'A%'
      AND ttd.monto_total_transaccion BETWEEN 200000 AND 300000

    UNION ALL --inicio de operaciones SET

    SELECT
        ttd.nro_tarjeta,
        ttd.total_cuotas_transaccion,
        ttd.monto_total_transaccion,
        TO_CHAR(ttd.fecha_transaccion, 'DD/MM/YYYY'),
        INITCAP(s.direccion),
        ROUND(ttd.monto_total_transaccion * 1.07)

    FROM trans_tarj_d ttd
    INNER JOIN sucursal s
        ON ttd.id_sucursal = s.id_sucursal
    WHERE UPPER(s.direccion) LIKE 'A%'
      AND ttd.monto_total_transaccion BETWEEN 300001 AND 500000

    UNION ALL

    SELECT
        ttd.nro_tarjeta,
        ttd.total_cuotas_transaccion,
        ttd.monto_total_transaccion,
        TO_CHAR(ttd.fecha_transaccion, 'DD/MM/YYYY'),
        INITCAP(s.direccion),
        ttd.monto_total_transaccion

    FROM trans_tarj_d ttd
    INNER JOIN sucursal s
        ON ttd.id_sucursal = s.id_sucursal
    WHERE UPPER(s.direccion) LIKE 'A%'
      AND ttd.monto_total_transaccion > 500000
      AND ttd.monto_total_transaccion >= 200000
);
    
COMMIT;
    
CREATE INDEX IDX_TTD_SUCURSAL ON trans_tarj_d (id_sucursal); --acelero el join las tablas usando id_sucursal
CREATE INDEX IDX_TTD_MONTO ON trans_tarj_d (monto_total_transaccion); ---aqui se optimiza el filtro del where para evitar tener q leer toda la tabla
CREATE INDEX IDX_SUCURSAL_DIR_UPPER ON sucursal (UPPER(direccion)); ---se optimiza el filtro de direccion los tres para evitar un fulls can
    
---Otorgar privilegio de acceso al usuario PRY2205_EFT_CON
GRANT SELECT ON T_ANALISIS_TARJETAS TO PRY2205_EFT_CON;

-- ===================================================================================================================================
-- ===================================================================================================================================
---USUARIO PRY2205_EFT_CON
---CONSULTA DE INFORMACIÓN
SELECT * FROM PRY2205_EFT_DES.VW_ANALISIS_DEUDORES_PERIODO;
SELECT * FROM PRY2205_EFT.T_ANALISIS_TARJETAS;
