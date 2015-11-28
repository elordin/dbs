using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DBS
{
    class Program
    {
        static string [] years = {"2009", "2013"};

        static Dictionary<string, int> federalStateIDs = new Dictionary<string, int>();
        static Dictionary<string, int> wahlkreisIDs = new Dictionary<string, int>();
        static Dictionary<string, int> partyIDs = new Dictionary<string, int>();
        static Dictionary<string, int> landeslistenIDs = new Dictionary<string, int>();
        static Dictionary<string, int> candidacyIDs = new Dictionary<string, int>();
        static StreamWriter wrges;

        static void Main(string[] args)
        {
            wrges = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_all.sql"));

            CreateElectionYears();
            ReadFederalStates();
            ReadWahlkreise();
            ReadParties();
            ReadCandidates();
            ReadVotes();
            ReadFreeDirectVotes();
            wrges.Flush();
            wrges.Close();
        }

        static void CreateElectionYears ()
        {
            string wl="";

            StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_electionyears.sql"));

            foreach (string s in years)
            {
                wl="insert into ElectionYear VALUES ("+s+");";
                wr.WriteLine(wl);
                wrges.WriteLine(wl);
            }

            wr.Flush();
            wr.Close();          

        }

        static void ReadFederalStates()
        {
            StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\FederalStates\wahlbewerber_listenplatz.csv"), System.Text.Encoding.UTF8);

            string wl = "";

            string line;
            string fs;
            int id = 1;

            sr.ReadLine();

            while ((line = sr.ReadLine()) != null)
            {
                fs = line.Split(';')[3];

                if (!federalStateIDs.Keys.Contains(fs))
                {
                    federalStateIDs[fs] = id;
                    id++;
                }                
            }

            sr.Close();

            StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_federalstates.sql"));

            foreach (string s in federalStateIDs.Keys)
            {
                wl = "insert into FederalState (fsid, name, outline, citizencount) VALUES (" + federalStateIDs[s] + ", '" + s + "', NULL, 0);";
                wr.WriteLine(wl);
                wrges.WriteLine(wl);
            }

            wr.Flush();
            wr.Close();
        }

        static void ReadWahlkreise()
        {
            int id = 1;
            string wl = "";

            foreach(string year in years)
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Wahlkreisnamen\Wahlkreisnamen_" + year + ".csv"), System.Text.Encoding.Default);
                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_wahlkreise_" + year+ ".sql"));

                string line;
                string [] wk;


                while ((line = sr.ReadLine()) != null)
                {
                    wk = line.Split(';');

                    wahlkreisIDs[year + "_" + wk[0]] = id;
                    wl = "insert into Wahlkreis (wkid, wknr, name, outline, fsid, year) VALUES (" + id.ToString() + ", " + wk[0] + ", '" + wk[1] + "', NULL, " + wk[2] + ", " + year + ");";
                    wr.WriteLine(wl);
                    wrges.WriteLine(wl);
                    id++;
                }

                sr.Close();
                wr.Flush();
                wr.Close();
            }
        }

        static void ReadParties()
        {
            int id = 1;
            string wl = "";

            foreach (string year in years)
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Wahlbewerber\wahlbewerber_" + year + ".csv"), System.Text.Encoding.UTF8);

                string line;
                string party;

                sr.ReadLine();

                while ((line = sr.ReadLine()) != null)
                {
                    party = line.Split(';')[6];

                    if (!partyIDs.Keys.Contains(party) && party != "")
                    {
                        partyIDs[party] = id;
                        id++;
                    }
                }
                sr.Close();
            }

            StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_parties.sql"));

            foreach (string s in partyIDs.Keys)
            {
                wl = "insert into Party (pid, name, shorthand, website, colourcode) VALUES (" + partyIDs[s] + ", '" + s + "', 'X" + partyIDs[s].ToString() + "','X','X');";
                wr.WriteLine(wl);
                wrges.WriteLine(wl);
            }

            wr.Flush();
            wr.Close();
            
        }

        static void ReadCandidates()
        {
            int cid=1;
            int llid = 1;
            string wl = "";

            foreach (string year in years)
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Wahlbewerber\wahlbewerber_" + year + ".csv"), System.Text.Encoding.UTF8);
                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_candidates_" + year + ".sql"));

                string line;
                string [] c;
                string federalState;
                string landeslistenYFSP;
                string titel="";
                string vorname ="";
                string supportingpartyid = "";

                sr.ReadLine();

                while ((line = sr.ReadLine()) != null)
                {
                    c = line.Split(';');
                    
                    if(year=="2009")
                    {
                        vorname = c[3];

                        string[] titels = { "Dr. ", "Dr. jur.", "Dr. Dr.", "Prof. Dr. ", "Prof. ", "Prof. Dr. Dr. "};

                        foreach(string t in titels)
                        { 
                            if(vorname.Contains(t))
                            {
                                titel=t;
                                vorname = vorname.Replace(t,"");
                                break;
                            }
                        }
                    }
                    else if(year=="2013")
                    {
                        titel = c[2];
                        vorname = c[3];                    
                    }

                    wl = "insert into Citizen (idno, title, firstname, lastname, dateofbirth, gender) VALUES (" + cid + ", '" + titel + "', '" + vorname + "', '" + c[4] + "', '1.1." + c[5] + ".', 'n');";
                    wr.WriteLine(wl);
                    wrges.WriteLine(wl);

                    wl ="insert into CandidatesData (idno) VALUES ("+cid+");";
                    wr.WriteLine(wl);
                    wrges.WriteLine(wl);

                    if(year=="2013")
                    {
                        federalState = GetFederalStateFromShortcut(c[8]);
                    }
                    else
                    {
                        federalState=c[8];
                    }

                    //Partymembership paused
                    //if (c[6] != "")
                    //{
                    //    wl="insert into PartyMembership (pid, idno) VALUES (" + partyIDs[c[6]].ToString() + ", " + cid + ");";
                    //    wr.WriteLine(wl);
                    //    wrges.WriteLine(wl);
                    //}

                    if (c[7] != "")
                    {
                        if (c[6] == "")
                        {
                            supportingpartyid = "NULL";
                        }
                        else
                        {
                            supportingpartyid = partyIDs[c[6]].ToString();
                        }

                        wl = "insert into Candidacy (wkid, idno, supportedby) VALUES (" + wahlkreisIDs[year + "_" + c[7]].ToString() + ", " + cid + ", "+ supportingpartyid + ");";
                        wr.WriteLine(wl);
                        wrges.WriteLine(wl);
                    }

                    if (c[8]!="")
                    {
                        landeslistenYFSP = year + "_" + partyIDs[c[6]].ToString() + "_" + federalStateIDs[federalState].ToString();

                        if (!landeslistenIDs.Keys.Contains(landeslistenYFSP))
                        {
                            wl = "insert into LandesListe (llid, year, pid, fsid) VALUES (" + llid.ToString() + ", " + year + ", " + partyIDs[c[6]].ToString() + ", " + federalStateIDs[federalState].ToString() + ");";
                            wr.WriteLine(wl);
                            wrges.WriteLine(wl);
                            landeslistenIDs[landeslistenYFSP]=llid;
                            llid++;
                        }
                        wl="insert into Landeslistenplatz (llid, idno, position) VALUES (" + landeslistenIDs[landeslistenYFSP] + ", " + cid + ", " + c[9] + ");";
                        wr.WriteLine(wl);
                        wrges.WriteLine(wl);
                    }


                    cid++;
                    
                }

                sr.Close();
                wr.Flush();
                wr.Close();
            }
        }

        static void ReadVotes()
        {
            string wl = "";

            foreach (string year in years)
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Ergebnis\kerg_" + year + ".csv"), System.Text.Encoding.Default);
                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_votes_" + year + ".sql"));

                string line;
                string[] c;                

                string [] partys = sr.ReadLine().Split(';');
                string lastparty="";
                int wkid;
                int numberofvotes = 0;

                for (int i=0; i < partys.Length; i++)
                {
                    if (partys[i] == "")
                        partys[i] = lastparty;
                    else
                        lastparty = partys[i];
                }

                while ((line = sr.ReadLine()) != null)
                {
                    c = line.Split(';');
                    wkid = wahlkreisIDs[year + "_" + c[0]];

                    for(int i=1; i < c.Length; i++)
                    {
                        if(c[i]=="")
                        {
                            numberofvotes = 0;
                        }
                        else
                        {
                            numberofvotes = Int32.Parse(c[i].Replace(" ",""));
                        }

                        if (numberofvotes != 0)
                        {
                            if (i % 2 == 1)
                            {
                                wl = "update Candidacy set votes = " + numberofvotes + " where wkid = " + wkid + " and supportedby = " + partyIDs[partys[i]] + ";";
                                wr.WriteLine(wl);
                                wrges.WriteLine(wl);
                            }
                            else
                            {
                                wl = "update AccumulatedZweitstimmenWK set votes = " +numberofvotes+" where wkid=" + wkid + " and llid = (select llid from landesliste where year = '" + year + "' and pid = " + partyIDs[partys[i]] + " and fsid = (select fsid from wahlkreis where wkid = " + wkid + "));";
                                wr.WriteLine(wl);
                                wrges.WriteLine(wl);
                            }
                        }
                    }
                }
                sr.Close();
                wr.Flush();
                wr.Close();

            }
        }

        static void ReadFreeDirectVotes()
        {
            string wl = "";

            foreach (string year in years)
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Ergebnis\udkerg_" + year + ".csv"), System.Text.Encoding.Default);
                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_votes_freedirect_" + year + ".sql"));

                string line;
                string[] c;

                string[] partys = sr.ReadLine().Split(';');

                int wkid;
                int numberofvotes = 0;

                while ((line = sr.ReadLine()) != null)
                {
                    c = line.Split(';');

                    wkid = wahlkreisIDs[year + "_" + c[0].Split(' ')[0]];

                    numberofvotes = Int32.Parse(c[2].Replace(" ", ""));

                    wl = "update Candidacy set votes = " + numberofvotes + " where wkid = " + wkid + " and idno in (select idno from candidates where lastname='"+c[1].Split(',')[0]+"') and supportedby IS NULL;";
                    wr.WriteLine(wl);
                    wrges.WriteLine(wl);

                }
                sr.Close();
                wr.Flush();
                wr.Close();

            }
        }



        static string GetFederalStateFromShortcut(string shortcut)
        {
            switch(shortcut)
            {
                case "BB": return "Brandenburg";
                case "BE": return "Berlin";
                case "BW": return "Baden-Württemberg";
                case "BY": return "Bayern";
                case "HB": return "Bremen";
                case "HE": return "Hessen";
                case "HH": return "Hamburg";
                case "MV": return "Mecklenburg-Vorpommern";
                case "NI": return "Niedersachsen";
                case "NW": return "Nordrhein-Westfalen";
                case "RP": return "Rheinland-Pfalz";
                case "SH": return "Schleswig-Holstein";
                case "SL": return "Saarland";
                case "SN": return "Sachsen";
                case "ST": return "Sachsen-Anhalt";
                case "TH": return "Thüringen";
                default: return "Bayern";
            }

        }
      
    }
}
