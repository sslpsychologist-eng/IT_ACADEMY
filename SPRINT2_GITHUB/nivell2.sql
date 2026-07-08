USE nova_bd_transactions;

# Exercici 1: Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
# Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(timestamp) AS data_transaccio, ROUND(SUM(amount),2) AS total_vendes
FROM transactions t
WHERE "declined" = 0
GROUP BY DATE(timestamp)
ORDER BY total_vendes DESC
LIMIT 5;
    
# Exercici 2: Presenta el nom, telèfon, país, data i amount, d'aquelles empreses que van realitzar transaccions 
# amb un valor comprès entre 350 i 400 euros i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
# Ordena els resultats de major a menor quantitat.

SELECT c.company_name, c.phone, c.country, DATE(t.timestamp) AS date, ROUND(t.amount, 2) AS amount
FROM companies c
JOIN transactions t ON c.company_id = t.business_id
WHERE t.amount BETWEEN 350 AND 400 
							AND DATE(t.timestamp) IN ("2015-04-29", "2018-07-20", "2024-03-13")
ORDER BY t.amount DESC;

# Exercici 3: Necessitem optimitzar l'assignació dels recursos i dependrà de la capacitat operativa que es requereixi, 
# per la qual cosa et demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
# però el departament de recursos humans és exigent i vol un llistat de les empreses on especifiquis si tenen igual o més de 400 transaccions o menys.

SELECT business_id, COUNT(id) AS total_transaccions,
CASE
  WHEN COUNT(id) >= 400 THEN "igual o més de 400 transaccions"
  ELSE "menys de 400 transaccions"
END AS transaccions_llindar400
FROM transactions t
GROUP BY business_id;

# Exercici 4: Elimina de la taula transaction el registre amb ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de dades.

USE transactions;

DELETE FROM transaction
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

# Exercici 5: La secció de màrqueting desitja tenir accés a informació específica per a realitzar anàlisi i estratègies efectives. 
# S'ha sol·licitat crear una vista que proporcioni detalls clau sobre les companyies i les seves transaccions. 
# Serà necessària que creïs una vista anomenada VistaMarketing que contingui la següent informació: 
# Nom de la companyia. Telèfon de contacte. País de residència. Mitjana de compra realitzat per cada companyia. Presenta la vista creada, ordenant les dades de major a menor mitjana de compra.

USE nova_bd_transactions;

DROP VIEW IF EXISTS VistaMarketing;

CREATE VIEW VistaMarketing AS
SELECT c.company_name, c.phone, c.country, ROUND(AVG(amount), 2) AS mitjana_compra
FROM companies c
JOIN transactions t
ON c.company_id = t.business_id
WHERE "declined" = 0
GROUP BY c.company_name, c.phone, c.country;

SELECT *
FROM VistaMarketing
ORDER BY mitjana_compra DESC;
