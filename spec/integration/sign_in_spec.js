describe("Authentication", () => {
  before(() => {
    cy.request("POST", "/api/rpc/purge");

    cy.request("POST", "/api/rpc/register", {
      name: "François Beausoleil",
      email: "francois@teksol.info",
      password: "monkeymonkey",
      group_name: "10ème Est-Calade",
      phone: "888 555-1212",
    });

    cy.request("POST", "/api/rpc/seed_user", {
      name: "Bob Smith",
      email: "bob@teksol.info",
      password: "lord robert stephenson smyth baden powell of gylwell",
      group_name: "10ème Est-Calade",
      phone: "888 555-1212",
    });
  })

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
    cy.get("input[type=email]").type("bob@teksol.info");
    cy.get("input[type=password]").type("lord robert stephenson smyth baden powell of gylwell");
    cy.contains("Sign In Now").click();

    // Temporary assertion to make sure we're authenticated
    cy.contains(/welcome to scoutges/i);
  });
})
