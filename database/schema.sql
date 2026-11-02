-- DDL Схема данных: Интеграция CRM-сделок со смарт-процессом экипажа

-- Справочник кандидатов / моряков
CREATE TABLE contacts_seafarers (
    contact_id SERIAL PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    rank_applied VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

-- Справочник судовладельцев и контрагентов
CREATE TABLE companies_counterparties (
    company_id SERIAL PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    inn_tax_id VARCHAR(30),
    country VARCHAR(50)
);

-- Реестр флота / судов
CREATE TABLE vessels_fleet (
    vessel_id SERIAL PRIMARY KEY,
    company_id INT REFERENCES companies_counterparties(company_id),
    vessel_name VARCHAR(100) NOT NULL,
    imo_number VARCHAR(20) UNIQUE,
    vessel_type VARCHAR(50)
);

-- Справочник открытых вакансий на судах
CREATE TABLE job_vacancies (
    vacancy_id SERIAL PRIMARY KEY,
    vessel_id INT REFERENCES vessels_fleet(vessel_id),
    rank_title VARCHAR(100) NOT NULL,
    salary_rate NUMERIC(10, 2),
    status VARCHAR(20) DEFAULT 'OPEN'
);

-- CRM: Сделка отдела продаж
CREATE TABLE crm_deals (
    deal_id SERIAL PRIMARY KEY,
    contact_id INT NOT NULL REFERENCES contacts_seafarers(contact_id),
    vacancy_id INT NOT NULL REFERENCES job_vacancies(vacancy_id),
    deal_stage VARCHAR(30) NOT NULL, -- 'NEW', 'INVOICE_SENT', 'PAID', 'CLOSED_LOST'
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Смарт-процесс: Экипаж (отображается во вкладке «Флот» конкретного судна)
CREATE TABLE smart_process_crews (
    assignment_id SERIAL PRIMARY KEY,
    deal_id INT UNIQUE REFERENCES crm_deals(deal_id),
    contact_id INT NOT NULL REFERENCES contacts_seafarers(contact_id),
    vessel_id INT NOT NULL REFERENCES vessels_fleet(vessel_id),
    rank_title VARCHAR(100) NOT NULL,
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'ACTIVE', -- 'ACTIVE', 'EXPIRING_SOON', 'COMPLETED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Планировщик задач: напоминание за 30 дней до окончания контракта
CREATE TABLE scheduled_tasks (
    task_id SERIAL PRIMARY KEY,
    assignment_id INT REFERENCES smart_process_crews(assignment_id),
    task_title VARCHAR(200) NOT NULL,
    due_date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE
);

-- Индексы для ускорения выборок
CREATE INDEX idx_smart_crews_vessel ON smart_process_crews(vessel_id, status);
CREATE INDEX idx_deals_stage ON crm_deals(deal_stage);
