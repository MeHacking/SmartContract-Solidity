// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.11;

contract UgovorNabavke {

    // Definisanje promenljivih

    address payable public adresaUgovora;
    address public kupac;
    address public prodavac;
    uint256 public kolicinaNarudzbine;
    uint256 public iznosNarudzbine;
    uint256 public uplata;
    bool public NarudzbinaJestePostavljena;
    bool public PlacanjeJesteZavrseno;
    bool public IznosPostavljen;
    bool public potvrda;

    // Eventovi

    event NarudzbinaPostavljena(address kupac, address prodavac, uint256 _kolicinaNarudzbine);
    event PlacanjeIzvrseno(address kupac, address prodavac, uint256 _kolicinaNarudzbine);
    event NarudzbinaPotvrdjena(address kupac, address prodavac, uint256 _kolicinaNarudzbine, uint256 _iznosNarudzbine);
    event iznosNarudzbinePostavljen(address kupac, address prodavac, uint256 _kolicinaNarudzbine, uint256 _iznosNarudzbine);
    event NarudzbinaPonistena(address kupac, address prodavac,uint256 kolicinaNarudzbine, uint256 iznosNarudzbine);
    event UplataIzvrsena(address kupac, uint256 iznosUplate);

    // Uslovi za pristup

    modifier samoKupac() {
        require(msg.sender == kupac, "Samo kupac moze pozvati ovu funkciju");
        _;
    }

    modifier samoProdavac() {
        require(msg.sender == prodavac, "Samo prodavac moze pozvati ovu funkciju");
        _;
    }

    modifier narudzbinaNijePostavljena() {
        require(!NarudzbinaJestePostavljena, "Narudzbina je vec postavljena");
        _;
    }

    modifier placanjeNijeZavrseno() {
        require(!PlacanjeJesteZavrseno, "Placanje je vec zavrseno");
        _;
    }

    modifier iznosJestePostavljen(){
        require(!IznosPostavljen, "Iznos je vec postavljen");
        _;
    }

    modifier potvrdjenaNarudzbina(){
        require(potvrda, "Kupac nije potvrdio narudzbinu");
        _;
    }

    // Deploy

    constructor (address _prodavac) payable {
        kupac = msg.sender;
        prodavac = _prodavac;
        adresaUgovora = payable(address(this));
        NarudzbinaJestePostavljena = false;
        PlacanjeJesteZavrseno = false;
        IznosPostavljen = false;
        potvrda = false;
    }

    // Funkcije

    // Funkcija za primanje Ethera na ugovor
    receive() external payable {}

    function postaviNarudzbinu(uint256 _kolicinaNarudzbine) external samoKupac narudzbinaNijePostavljena {
        kolicinaNarudzbine = _kolicinaNarudzbine;
        NarudzbinaJestePostavljena = true;

        // Emitovanje dogadjaja
        emit NarudzbinaPostavljena(kupac, prodavac, kolicinaNarudzbine);
    }

    function postaviIznosNarudzbine(uint256 _iznosNarudzbine) external samoProdavac iznosJestePostavljen {
        require(NarudzbinaJestePostavljena, "Narudzbina jos nije postavljena");
        
        iznosNarudzbine = _iznosNarudzbine;
        IznosPostavljen = true;

        // Emitovanje dogadjaja
        emit iznosNarudzbinePostavljen(kupac, prodavac, kolicinaNarudzbine, iznosNarudzbine);
    }

    function potvrdiNarudzbinu() external samoKupac {
        require(NarudzbinaJestePostavljena, "Narudzbina jos nije postavljena");
        require(IznosPostavljen, "Iznos jos nije postavljen");
        potvrda = true;

        // Emitovanje dogadjaja
        emit NarudzbinaPotvrdjena(kupac, prodavac, kolicinaNarudzbine, iznosNarudzbine);
    }

    function ponistiNarudzbinu() external samoKupac {
        require(NarudzbinaJestePostavljena, "Narudzbina jos nije postavljena");
        require(IznosPostavljen, "Iznos jos nije postavljen");
        IznosPostavljen = false;

        // Emitovanje dogadjaja
        emit NarudzbinaPonistena(kupac, prodavac, kolicinaNarudzbine, iznosNarudzbine);
    }

    function izvrsiPlacanje() external samoKupac placanjeNijeZavrseno potvrdjenaNarudzbina payable {
        require(address(this).balance >= iznosNarudzbine, "Nedovoljno sredstava za transfer");
        require(NarudzbinaJestePostavljena, "Narudzbina jos nije postavljena");
        require(IznosPostavljen, "Iznos jos nije postavljen");
        require(potvrda, "Niste potvrdili narudzbinu, proverite postavljen iznos");
        require(adresaUgovora.balance >= iznosNarudzbine, "Nedovoljno sredstava za transfer");

        // Transfer ETH od kupca ka prodavcu
        (bool success, ) = prodavac.call{value: iznosNarudzbine}("");
        require(success, "Neuspesan transfer ETH-a");

        PlacanjeJesteZavrseno = true;

        // Emitovanje dogadjaja
        emit PlacanjeIzvrseno(kupac, prodavac, iznosNarudzbine);
    }

    function UplatiNaUgovor() external samoKupac payable {
        require(msg.value > 0, "Morate poslati nenulti iznos");
        
        uplata += msg.value;
        
        // Emitovanje dogadjaja
        emit UplataIzvrsena(kupac, msg.value);
    }
}