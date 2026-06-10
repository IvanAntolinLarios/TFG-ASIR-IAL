drop database db_tfg;
CREATE DATABASE IF NOT EXISTS db_tfg;
USE db_tfg;

-- 1. Tabla de Usuarios (Cumpliendo ISO 27001: Control de Acceso)
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL, -- Almacenaremos HASH, no texto plano
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_username (username) -- Índice para login rápido
) ENGINE=InnoDB;

-- 2. Tabla de Auditoría (Cumpliendo ISO 27001: Trazabilidad)
CREATE TABLE audit_log (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  action VARCHAR(100),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. Tabla de Estadísticas (Con la ID que sugeriste)
CREATE TABLE web_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  new_users_count INT DEFAULT 0,
  login_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE PROCEDURE sp_generate_web_stats(IN p_start DATE, IN p_end DATE)
BEGIN
  
  IF p_end > CURDATE() THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Error: La fecha de fin no puede ser superior a la fecha actual.';
  ELSEIF p_start > p_end THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Error: La fecha de inicio no puede ser posterior a la de fin.';
  ELSE
    INSERT INTO web_stats (start_date, end_date, new_users_count, login_count)
    SELECT 
      p_start, 
      p_end,
      (SELECT COUNT(*) FROM users WHERE DATE(created_at) BETWEEN p_start AND p_end),
      (SELECT COUNT(*) FROM audit_log WHERE action = 'LOGIN_SUCCESS' AND DATE(timestamp) BETWEEN p_start AND p_end);
  END IF;
END;

CREATE EVENT ev_monthly_stats_summary
ON SCHEDULE EVERY 1 MONTH
STARTS '2026-06-01 00:01:00' -- Empieza el primer día del mes siguiente
DO
BEGIN
  
  DECLARE fecha_inicio DATE;
  DECLARE fecha_fin DATE;

  -- Calculamos el primer y último día del mes anterior
  SET fecha_inicio = DATE_SUB(DATE_FORMAT(NOW(), '%Y-%m-01'), INTERVAL 1 MONTH);
  SET fecha_fin = LAST_DAY(DATE_SUB(NOW(), INTERVAL 1 MONTH));

  CALL sp_generate_web_stats(fecha_inicio, fecha_fin);

END;

CREATE TRIGGER tr_audit_email_or_pass_change
AFTER UPDATE ON users
FOR EACH ROW
BEGIN

  -- Log de Email
  IF OLD.email <> NEW.email THEN
      INSERT INTO audit_log (user_id, action)
      VALUES (NEW.id, CONCAT('CAMBIO EMAIL: de <', OLD.email, '> a <', NEW.email, '>'));
  END IF;

  -- Log de Password
  IF OLD.password_hash <> NEW.password_hash THEN
      INSERT INTO audit_log (user_id, action)
      VALUES (NEW.id, 'EVENTO_SEGURIDAD: Cambio de contraseña efectuado');
  END IF;

END;

CREATE TRIGGER tr_audit_delete_user
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
  
  INSERT INTO audit_log (user_id, action)
  VALUES (OLD.id, 'DELETE_USER: Cuenta eliminada por el usuario');

END;