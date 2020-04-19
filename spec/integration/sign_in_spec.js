describe("Authentication", () => {
  it("fails to sign in when not using email / password", () => {
    cy.visit("/");
    cy.contains("Sign In Now").click();

    cy.contains("Invalid username or password");
  });

  it("fails to sign in when using the correct email but wrong password", () => {
    cy.visit("/");
    cy.get("input[type=email]").type("francois@teksol.info");
    cy.get("input[type=password]").type("powwow");
    cy.contains("Sign In Now").click();

    cy.contains("Invalid username or password");
  });

  it("fails to sign in when using an incorrect email", () => {
    cy.visit("/");
    cy.get("input[type=email]").type("boubou@teksol.info");
    cy.get("input[type=password]").type("monkeymonkey");
    cy.contains("Sign In Now").click();

    cy.contains("Invalid username or password");
  });

  it("signs in with a valid email / password combination", () => {
    cy.visit("/");
    cy.get("input[type=email]").type("francois@teksol.info");
    cy.get("input[type=password]").type("monkeymonkey");
    cy.contains("Sign In Now").click();

    cy.contains(/welcome to scoutges/i);
  });
})
