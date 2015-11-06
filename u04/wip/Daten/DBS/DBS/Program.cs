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

        static void Main(string[] args)
        {
            ReadFederalStates();
            ReadWahlkreise();
            ReadParties();
            ReadCandidates();
        }

        static void ReadFederalStates()
        {
            StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\FederalStates\wahlbewerber_listenplatz.csv"), System.Text.Encoding.UTF8);

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
                }

                id++;
            }

            sr.Close();

            StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_federalstates.sql"));

            foreach (string s in federalStateIDs.Keys)
            {
                wr.WriteLine("insert into FederalState (name, outline) VALUES ('" + s + "', NULL);");
            }

            wr.Flush();
            wr.Close();
        }

        static void ReadWahlkreise()
        {
            int id = 1;
            foreach(string year in years)
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Wahlkreisnamen\Wahlkreisnamen_" + year + ".csv"), System.Text.Encoding.Default);
                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_wahlkreise_" + year + ".sql"));

                string line;
                string [] wk;


                while ((line = sr.ReadLine()) != null)
                {
                    wk = line.Split(';');
                    wahlkreisIDs[wk[0]] = id;
                    wr.WriteLine("insert into Wahlkreis (wkid, wknr, name, outline, fsid) VALUES ("+id.ToString()+", " + wk[0] + ", '" + wk[1] + "', NULL, "+wk[2]+");");
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
            foreach (string year in new[] { "2009", "2013" })
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Wahlbewerber\wahlbewerber_" + year + ".csv"), System.Text.Encoding.UTF8);

                string line;
                string party;                

                sr.ReadLine();

                while ((line = sr.ReadLine()) != null)
                {
                    party = line.Split(';')[6];

                    if (!partyIDs.Keys.Contains(party) && party!="")
                    {                        
                        partyIDs[party] = id;
                        id++;
                    }
                }

                sr.Close();

                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_parties_" + year + ".sql"));

                foreach (string s in partyIDs.Keys)
                {
                    wr.WriteLine("insert into Party (pid, name, shorthand, website, colourcode) VALUES ("+partyIDs[s]+", '" + s + "', 'X','X','X');");
                }

                wr.Flush();
                wr.Close();
            }
        }

        static void ReadCandidates()
        {
            int cid=1;
            int llid = 1;

            foreach (string year in new[] { "2009", "2013" })
            {
                StreamReader sr = new StreamReader(File.OpenRead(@"..\..\..\..\Wahlbewerber\wahlbewerber_" + year + ".csv"), System.Text.Encoding.UTF8);
                StreamWriter wr = new StreamWriter(File.Create(@"..\..\..\..\sql\insert_candidates_" + year + ".sql"));

                string line;
                string [] c;
                string landeslistenYFSP;

                sr.ReadLine();

                while ((line = sr.ReadLine()) != null)
                {
                    c = line.Split(';');
                    wr.WriteLine("insert into Citizen (idno, title, firstname, lastname, dateofbirth, gender) VALUES ("+cid+", '" + c[2] + "', '" + c[3] + "', '" + c[4] + "', '1.1." + c[5] + ".', 'p');");
                    wr.WriteLine("insert into CandidatesData (idno) VALUES ("+cid+");");

                    if (c[6] != "")
                    {
                        wr.WriteLine("insert into PartyMembership (pid, idno) VALUES (" + partyIDs[c[6]].ToString() + ", " + cid + ");");
                    }

                    if (c[7] != "")
                    {
                        wr.WriteLine("insert into Candidacy (wkid, idno) VALUES (" + wahlkreisIDs[c[7]].ToString() + ", " + cid + ");");
                    }

                    if (c[8]!="")
                    {
                        landeslistenYFSP = year + partyIDs[c[6]].ToString() + federalStateIDs[GetFederalStateFromShortcut(c[8])].ToString();

                        if (!landeslistenIDs.Keys.Contains(landeslistenYFSP))
                        {
                            wr.WriteLine("insert into LandesListe (llid, year, pid, fsid) VALUES (" + llid.ToString() + ", " + year + ", " + partyIDs[c[6]].ToString() + ", " + federalStateIDs[GetFederalStateFromShortcut(c[8])].ToString() + ");");
                            landeslistenIDs[landeslistenYFSP]=llid;
                            llid++;
                        }
                        wr.WriteLine("insert into Landeslistenplatz (llid, idno, position) VALUES (" + landeslistenIDs[landeslistenYFSP] + ", " + cid + ", " + c[9] + ");");
                    }


                    cid++;
                    
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
