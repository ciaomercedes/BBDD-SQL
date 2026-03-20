/*CASO 1: ANALISIS DE FACTURAS*/
SELECT 
    NUMFACTURA AS "N° Factura",
    TO_CHAR(FECHA, 'DD "DE" MONTH YYYY') AS "Fecha Emisión",   
    LPAD(RUTCLIENTE, 10, '0') AS "RUT cliente",
    REPLACE(TO_CHAR(neto, '$9,999,999'), ',', '.') AS "Monto neto",
    REPLACE(TO_CHAR(iva, '$9,999,999'), ',', '.') AS "Monto IVA",
    REPLACE(TO_CHAR(total, '$9,999,999'), ',', '.') AS "Total Factura",
    CASE 
        WHEN NETO BETWEEN 0 AND 50000 THEN 'BAJO'
        WHEN NETO BETWEEN 50001 AND 100000 THEN 'MEDIO'
        ELSE 'ALTO'
    END AS "Categoría Monto",
    CASE 
        WHEN CODPAGO = 1 THEN 'EFECTIVO'
        WHEN CODPAGO = 2 THEN 'TARJETA DEBITO'
        WHEN CODPAGO = 3 THEN 'TARJETA CREDITO'
        ELSE 'CHEQUE'
    END AS "Forma de Pago"
FROM FACTURA
WHERE EXTRACT(YEAR FROM FECHA) = EXTRACT(YEAR FROM SYSDATE) - 1
ORDER BY FECHA DESC, NETO DESC;

/* CLASIFICACIÓN DE CLIENTES */
SELECT 
    RTRIM(LPAD(RUTCLIENTE, 12, '*')) AS "Rut",
    INITCAP (NOMBRE) AS "Cliente",
    NVL(TO_CHAR(TELEFONO), 'Sin telefono') AS "Teléfono",    
    NVL(TO_CHAR(CODCOMUNA), 'Sin comuna') AS "Comuna",
    ESTADO,
    CASE 
        WHEN (SALDO / CREDITO) < 0.5 THEN 'BUENO (' || TO_CHAR(CREDITO - SALDO, '$9,999,999') || ')'
        WHEN (SALDO / CREDITO) BETWEEN 0.5 AND 0.8 THEN 'REGULAR (' || TO_CHAR(SALDO, '$9,999,999') || ')'
        ELSE 'CRITICO'
    END AS "Estado Crédito",
    CASE 
        WHEN MAIL IS NOT NULL THEN 
            SUBSTR(MAIL, INSTR(MAIL, '@') + 1)
        ELSE 'Correo no registrado'
    END AS "Dominio Correo"
FROM CLIENTE
WHERE ESTADO = 'A' AND CREDITO > 0
ORDER BY NOMBRE ASC;

/* STOCK DE PRODUCTOS */
UNDEFINE TIPOCAMBIO_DOLAR;
UNDEFINE UMBRAL_BAJO;
UNDEFINE UMBRAL_ALTO;

SELECT
    CODPRODUCTO AS "ID",
    INITCAP(DESCRIPCION) AS "Descripción de Producto",
    LPAD(CASE
        WHEN valorcompradolar IS NULL THEN 'Sin registro'
        ELSE REPLACE(TO_CHAR(valorcompradolar, '9990.00'),'.',',') || ' USD' 
    END, 16, ' ') AS "Compra en USD",
    LPAD(CASE
        WHEN valorcompradolar IS NULL THEN 'Sin registro'
        ELSE REPLACE(TO_CHAR(valorcompradolar * &&TIPOCAMBIO_DOLAR, '$9,999,999'),',','.')  || ' PESOS' 
    END, 17, ' ') AS "USD convertido",
    LPAD(NVL(TO_CHAR(totalstock), 'Sin datos'), 7,' ') AS "Stock",
    CASE
        WHEN totalstock IS NULL THEN 'Sin datos'
        WHEN totalstock < &&UMBRAL_BAJO THEN '¡ALERTA stock muy bajo!'
        WHEN totalstock BETWEEN &&UMBRAL_BAJO AND &&UMBRAL_ALTO THEN '¡Reabastecer pronto!'
    ELSE 'OK'
    END AS "Alerta Stock",
    LPAD(CASE
    WHEN totalstock > 80 AND valorcompradolar IS NOT NULL THEN
        TO_CHAR((vunitario * 0.9), '$9,999,999')
        ELSE 'N/A'
        END,15,' ') AS "Precio Oferta"
FROM PRODUCTO
WHERE LOWER(DESCRIPCION) LIKE '%zapato%' AND LOWER(PROCEDENCIA) = 'i'
ORDER BY CODPRODUCTO DESC;