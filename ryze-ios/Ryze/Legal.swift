import Foundation

// Corrected, web-verified legal copy (Albania). Law 124/2024 (not repealed 9887),
// ASD deposit insurance 2,500,000 ALL, AML recipient AIF, personal NID tax id.
// PROTOTYPE, final wording requires Raiffeisen legal sign-off.

struct ConsentDef: Identifiable {
    let id: String
    let mandatory: Bool
    let label: String
}

enum Legal {
    static let consents: [ConsentDef] = [
        .init(id: "agreements", mandatory: true,
              label: "I agree to the Framework Agreement, General Terms, Tariff and Privacy Policy, the Information Notice (Law 124/2024), and I confirm the KYC/AML, beneficial-owner, PEP, tax (CRS/FATCA) and deposit-insurance (ASD) declarations."),
        .init(id: "biometric", mandatory: true,
              label: "I consent to the automated processing of my facial image (liveness check) to verify my identity."),
        .init(id: "marketing", mandatory: false,
              label: "Send me personalised offers, news and rewards from Raiffeisen. (Optional, turn off anytime.)"),
    ]

    static let disclaimer = "Ryze is a hackathon prototype for Raiffeisen Bank Albania. It is not a live banking service. All legal texts, consents and figures are drafts requiring final legal and compliance review."

    static let depositInsurance = "Your money is protected. Deposits at Raiffeisen Bank Sh.a. are insured by the Albanian Deposit Insurance Agency (ASD) under Law No. 53/2014, up to 2,500,000 ALL (about €26,000, indicative) per depositor, per bank. Foreign-currency deposits are converted to ALL at the Bank of Albania official rate on the day of compulsory liquidation."

    static let infoNotice = "Controller: Raiffeisen Bank Sh.a. (Albania). We process your identity, contact, ID image and a biometric liveness scan, tax and financial-profile data to open and run your account, to meet legal obligations (AML, Law 9917/2008; CRS, Law 4/2020; FATCA) and, with your consent, for the liveness check. Recipients include the Bank of Albania, the Financial Intelligence Agency (AIF), the General Directorate of Taxation and the ASD. You have rights of access, rectification, erasure, restriction, objection, portability and consent withdrawal under Law No. 124/2024 (complaints: idp.al)."
}
