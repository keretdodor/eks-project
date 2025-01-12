/**
 * @param {HTMLDivElement} div
 * @param {number} id 
 */
function handlePersonClick(div, id) {
    const cssClass = div.className;
    if (cssClass === "person-disabled") { return; }
    
    fetch(`${backend}/delete/${id}`, { 
        method: "DELETE",
        headers: {
            "Content-Type": "application/json"
        }
    })
    .then(res => {
        if (res.status === 200) {
            const parent = div.parentElement;
            if (parent) {
                parent.removeChild(div);
                if (parent.children.length === 0) {
                    const grandparent = parent.parentElement;
                    if (grandparent) {
                        grandparent.removeChild(parent);
                    }
                }
            }
        } else if (res.status === 404) {
            alert("Person not found");
        } else {
            alert("Error deleting person");
        }
    })
    .catch(err => {
        console.error("Error:", err);
        alert("Error deleting person");
    });
}

function handleClick() {
    const modal = document.getElementById('personModal');
    if (modal) {
        modal.style.display = 'block';
    }
}

function closeModal() {
    const modal = document.getElementById('personModal');
    if (modal) {
        modal.style.display = 'none';
    }
    // Clear form
    const form = document.getElementById('addPersonForm');
    if (form) {
        form.reset();
    }
}

window.onclick = function(event) {
    const modal = document.getElementById('personModal');
    if (modal && event.target == modal) {
        closeModal();
    }
}

// Handle form submission
document.getElementById('addPersonForm')?.addEventListener('submit', function(event) {
    event.preventDefault();
    
    // Collect form data
    const firstName = document.getElementById('firstName')?.value;
    const lastName = document.getElementById('lastName')?.value;
    const age = document.getElementById('age')?.value;
    const address = document.getElementById('address')?.value;
    const workplace = document.getElementById('workplace')?.value;

    if (!firstName || !lastName || !age || !address || !workplace) {
        alert("Please fill in all fields");
        return;
    }

    // send put request with person object in body
    fetch(`${backend}/add`, {
        method: "PUT",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            firstName,
            lastName,
            age,
            address,    // Order matches Person constructor
            workplace
        })
    })
    .then(res => {
        if (res.status === 200) {
            return res.text();
        } else {
            throw new Error(`Server returned status: ${res.status}`);
        }
    })
    .then(id => {
        // Create new person div
        const newPerson = document.createElement('div');
        newPerson.className = "person";
        newPerson.onclick = function() {
            handlePersonClick(this, parseInt(id));
        };

        // Create person elements
        newPerson.innerHTML = `
            <h3>${firstName} ${lastName}</h3>
            <p>Age: ${age}</p>
            <p>Address: ${address}</p>
            <p>Workplace: ${workplace}</p>
        `;

        // Get the tableContainer div
        const people = document.getElementById('tableContainer');
        if (!people) return;

        // get the last child of the tableContainer div
        let parent = people.children[people.children.length - 1];

        // check if parent has 3 children or doesn't exist. If it does, create a new one
        if (!parent || parent.childElementCount === 3) {
            parent = document.createElement('div');
            parent.className = "container";
            people.appendChild(parent);
        }

        // Append new person div to the parent div
        parent.appendChild(newPerson);
        
        // Close modal and reset form
        closeModal();
    })
    .catch(err => {
        console.error("Error:", err);
        alert("Error adding person");
    });
});