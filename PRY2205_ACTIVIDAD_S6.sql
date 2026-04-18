--============================================--
/*        LIMPIEZA: Borrado de objetos        */
--============================================--
DROP TABLE RECAUDACION_BONOS_MEDICOS CASCADE CONSTRAINTS;
DELETE FROM CANT_BONOS_PACIENTES_ANNIO;
COMMIT;

--============================================--
/*         CASO 1: TABLA RECAUDACIONES        */
--============================================--
CREATE TABLE RECAUDACION_BONOS_MEDICOS AS

SELECT
    REPLACE(TO_CHAR(bc.rut_med, '09,999,999'),',','.') || '-' || med.dv_run AS RUT_MÉDICO,
    UPPER(med.pnombre || ' ' || med.apaterno || ' ' || med.amaterno) AS NOMBRE_MÉDICO,
    REPLACE(TO_CHAR(ROUND(SUM(bc.costo)), '$999,999,999'), ',', '.') AS TOTAL_RECAUDADO,
    LPAD(INITCAP(NVL(unicon.nombre, 'Sin unidad')),35,' ') AS UNIDAD_MEDICA
FROM BONO_CONSULTA bc
INNER JOIN MEDICO med
    ON bc.rut_med = med.rut_med
LEFT JOIN UNIDAD_CONSULTA unicon
    ON unicon.uni_id = med.uni_id
WHERE med.car_id NOT IN (100, 500, 600)
AND bc.fecha_bono >= TRUNC(ADD_MONTHS(SYSDATE, -12), 'YEAR')
AND bc.fecha_bono < TRUNC(SYSDATE, 'YEAR')
GROUP BY
    bc.rut_med,
    med.dv_run,
    med.pnombre,
    med.apaterno,
    med.amaterno,
    unicon.nombre
ORDER BY SUM(bc.costo) ASC;


--============================================--
/*     CASO 2: PERDIDAS POR ESPECIALIDAD      */
--============================================--
SELECT
    UPPER(espmed.nombre) AS "ESPECIALIDAD MEDICA",
    COUNT(bc.id_bono) AS "CANTIDAD BONOS",
    LPAD(REPLACE(TO_CHAR(SUM(bc.costo), '$999,999,999'),',','.'),15) AS "MONTO PÉRDIDA",
    TO_CHAR(MIN(bc.fecha_bono), 'DD-MM-YYYY') AS "FECHA BONO",
    CASE
        WHEN MAX(EXTRACT(YEAR FROM bc.fecha_bono)) >= EXTRACT(YEAR FROM SYSDATE) -1 
        THEN 'COBRABLE'
        ELSE 'INCOBRABLE' 
    END AS "ESTADO DE COBRO"
FROM BONO_CONSULTA bc
INNER JOIN ESPECIALIDAD_MEDICA espmed
    ON espmed.esp_id = bc.esp_id
WHERE NOT EXISTS ( SELECT 1
                    FROM PAGOS p
                    WHERE p.id_bono = bc.id_bono)
GROUP BY espmed.nombre
ORDER BY 2 ASC, 3 DESC;


--============================================--
/*     CASO 3: PROYECCION PRESUPUESTARIA      */
--============================================--
INSERT INTO CANT_BONOS_PACIENTES_ANNIO
(ANNIO_CALCULO,
    PAC_RUN,
    DV_RUN,
    EDAD,
    CANTIDAD_BONOS,
    MONTO_TOTAL_BONOS,
    SISTEMA_SALUD
)

SELECT
    EXTRACT(YEAR FROM SYSDATE) AS ANNIO_CALCULO,
    pac.pac_run,
    pac.dv_run,
    CEIL(MONTHS_BETWEEN(SYSDATE, pac.fecha_nacimiento) / 12) AS EDAD,
    NVL(bc.total_bonos, 0) AS CANTIDAD_BONOS,
    NVL(bc.monto_total, 0) AS MONTO_TOTAL_BONOS,
    NVL(UPPER(ss.descripcion), 'Sin Sistema') AS SISTEMA_SALUD
    
FROM PACIENTE pac
LEFT JOIN SALUD s
    ON pac.sal_id = s.sal_id
    
LEFT JOIN SISTEMA_SALUD ss
    ON s.tipo_sal_id = ss.tipo_sal_id
    
LEFT JOIN (
    SELECT
        pac_run,
        COUNT(id_bono) AS total_bonos,
        SUM(costo) AS monto_total
    FROM BONO_CONSULTA
    WHERE EXTRACT(YEAR FROM fecha_bono) = EXTRACT(YEAR FROM SYSDATE)
    GROUP BY pac_run
) bc
    ON pac.pac_run = bc.pac_run

WHERE NVL(bc.total_bonos, 0) <= ( 
    SELECT ROUND(AVG(total_bonos)) 
    FROM ( 
        SELECT COUNT(id_bono) AS total_bonos 
    FROM BONO_CONSULTA WHERE EXTRACT(YEAR FROM fecha_bono) = EXTRACT(YEAR FROM SYSDATE) - 1 
GROUP BY pac_run 
)) AND ss.tipo_sal_id NOT IN ('I', 'CP')

ORDER BY CANTIDAD_BONOS ASC, EDAD DESC;
    
COMMIT;
    
SELECT * FROM CANT_BONOS_PACIENTES_ANNIO;