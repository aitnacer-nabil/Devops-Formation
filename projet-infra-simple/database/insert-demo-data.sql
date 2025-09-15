USE demo_db;

INSERT IGNORE INTO users (nom, email) VALUES
('Alice Martin', 'alice.martin@example.com'),
('Bob Dupont', 'bob.dupont@example.com'),
('Clara Leblanc', 'clara.leblanc@example.com'),
('David Moreau', 'david.moreau@example.com'),
('Emma Rousseau', 'emma.rousseau@example.com'),
('François Simon', 'francois.simon@example.com'),
('Gabrielle Dubois', 'gabrielle.dubois@example.com'),
('Hugo Petit', 'hugo.petit@example.com'),
('Isabelle Leroy', 'isabelle.leroy@example.com'),
('Julien Bernard', 'julien.bernard@example.com');

-- Vérification des données insérées
SELECT 'Nombre d\'utilisateurs créés:' as Info, COUNT(*) as Total FROM users;
SELECT * FROM users ORDER BY date_creation;