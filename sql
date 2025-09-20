-- Employees Table: Stores user information
CREATE TABLE IF NOT EXISTS employees(
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    manager_id INTEGER REFERENCES employees(id) -- Self-referencing key for hierarchy
);

-- Goals Table: Stores performance goals
CREATE TABLE IF NOT EXISTS goals(
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Draft', 'In Progress', 'Completed', 'Cancelled'))
);

-- Tasks Table: Stores tasks related to each goal
CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    goal_id INTEGER REFERENCES goals(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT FALSE
);

-- Feedback Table: Stores feedback from managers on goals
CREATE TABLE IF NOT EXISTS feedback (
    id SERIAL PRIMARY KEY,
    goal_id INTEGER REFERENCES goals(id) ON DELETE CASCADE,
    manager_id INTEGER REFERENCES employees(id),
    feedback_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Automated Feedback Trigger Function
CREATE OR REPLACE FUNCTION goal_completed_feedback()
RETURNS TRIGGER AS $$
BEGIN
    -- If a goal's status is updated to 'Completed'
    IF NEW.status = 'Completed' AND OLD.status != 'Completed' THEN
        -- Insert a positive, automated feedback message
        INSERT INTO feedback (goal_id, manager_id, feedback_text, created_at)
        VALUES (
            NEW.id, 
            (SELECT manager_id FROM employees WHERE id = NEW.employee_id), 
            'Great job on completing this goal!', 
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger that executes the function after a goal is updated
CREATE TRIGGER goal_completed_trigger
AFTER UPDATE ON goals
FOR EACH ROW
EXECUTE FUNCTION goal_completed_feedback();
