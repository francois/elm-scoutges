describe("Registration", () => {
  before(() => {
    cy.request("POST", "/api/rpc/purge");
  })

  it("registers with valid credentials", () => {
    cy.visit("/");
    cy.contains("Register").click()
    cy.contains("Group's Name").find("input").type("13th Group of St-Basile-Le-Grand");
    cy.contains("Your Name").find("input").type("Homer Simpson");
    cy.contains("Phone").find("input").type("555 555-1212");
    cy.contains("Email").find("input").type("homer.simpson@teksol.info");
    cy.contains("Password").find("input").type("doh");
    cy.contains("Register Now").click();

    cy.contains(/welcome to scoutges/i);
  })

  it("fails to register with duplicate email address", () => {
    cy.visit("/");
    cy.contains("Register").click()
    cy.contains("Group's Name").find("input").type("13th Group of St-Basile-Le-Grand");
    cy.contains("Your Name").find("input").type("Homer Simpson");
    cy.contains("Phone").find("input").type("555 555-1212");
    cy.contains("Email").find("input").type("homer.simpson@teksol.info");
    cy.contains("Password").find("input").type("doh");
    cy.contains("Register Now").click();

    cy.contains("Invalid email or password");
  })
})
