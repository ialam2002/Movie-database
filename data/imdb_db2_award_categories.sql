-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: localhost    Database: imdb_db2
-- ------------------------------------------------------
-- Server version	9.2.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `award_categories`
--

DROP TABLE IF EXISTS `award_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `award_categories` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `award_show_id` int NOT NULL,
  `category_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uq_show_category` (`award_show_id`,`category_name`),
  CONSTRAINT `award_categories_ibfk_1` FOREIGN KEY (`award_show_id`) REFERENCES `award_shows` (`award_show_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=111 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `award_categories`
--

LOCK TABLES `award_categories` WRITE;
/*!40000 ALTER TABLE `award_categories` DISABLE KEYS */;
INSERT INTO `award_categories` VALUES (6,1,'Actor In A Leading Role'),(64,1,'Actor In A Leading Role - Drama Series Or Television Movie'),(65,1,'Actor In A Leading Role - Musical Or Comedy Series Or Television Movie'),(66,1,'Actor In A Supporting Role - Series Or Television Movie'),(59,1,'Actor In A Supporting Role - Television Series'),(42,1,'Actor In A Television Series'),(52,1,'Actor In A Television Series - Drama'),(51,1,'Actor In A Television Series - Musical Or Comedy'),(5,1,'Actress In A Leading Role'),(63,1,'Actress In A Leading Role - Drama Series Or Television Movie'),(22,1,'Actress In A Leading Role - Musical Or Comedy'),(67,1,'Actress In A Leading Role - Musical Or Comedy Series Or Television Movie'),(62,1,'Actress In A Supporting Role - Series Or Television Movie'),(60,1,'Actress In A Supporting Role - Television Series'),(43,1,'Actress In A Television Series'),(53,1,'Actress In A Television Series - Drama'),(54,1,'Actress In A Television Series - Musical Or Comedy'),(3,1,'Best Director - Motion Picture'),(75,1,'Best Motion Picture - Animated'),(26,1,'Best Motion Picture - Drama'),(16,1,'Best Motion Picture - Foreign Language'),(27,1,'Best Motion Picture - Musical or Comedy'),(10,1,'Best Original Score - Motion Picture'),(40,1,'Best Original Song - Motion Picture'),(74,1,'Best Performance by an Actor in a Limited Series or a Motion Picture Made for Television'),(19,1,'Best Performance by an Actor in a Motion Picture - Drama'),(20,1,'Best Performance by an Actor in a Motion Picture - Musical or Comedy'),(70,1,'Best Performance by an Actor in a Supporting Role in a Series, Limited Series or Motion Picture Made for Television'),(2,1,'Best Performance by an Actor in a Supporting Role in any Motion Picture'),(56,1,'Best Performance by an Actor In A Television Series - Drama'),(58,1,'Best Performance by an Actor in a Television Series - Musical or Comedy'),(73,1,'Best Performance by an Actress in a Limited Series or a Motion Picture Made for Television'),(18,1,'Best Performance by an Actress in a Motion Picture - Drama'),(68,1,'Best Performance by an Actress in a Motion Picture - Musical or Comedy'),(69,1,'Best Performance by an Actress in a Supporting Role in a Series, Limited Series or Motion Picture Made for Television'),(1,1,'Best Performance by an Actress in a Supporting Role in any Motion Picture'),(55,1,'Best Performance by an Actress In A Television Series - Drama'),(57,1,'Best Performance by an Actress in a Television Series - Musical or Comedy'),(9,1,'Best Screenplay - Motion Picture'),(72,1,'Best Television Limited Series or Motion Picture Made for Television'),(44,1,'Best Television Series - Drama'),(50,1,'Best Television Series - Musical or Comedy'),(76,1,'Carol Burnett Award'),(29,1,'Cecil B. deMille Award'),(14,1,'Cinematography'),(25,1,'Cinematography - Black And White'),(24,1,'Cinematography - Color'),(30,1,'Documentary'),(39,1,'Famous Silent Filmstars'),(15,1,'Foreign Film - English Language'),(35,1,'Foreign Film - Foreign Language'),(28,1,'Henrietta Award (World Film Favorite)'),(23,1,'Henrietta Award (World Film Favorites)'),(32,1,'Hollywood Citizenship Award'),(48,1,'International News Coverage'),(13,1,'Juvenile Performance'),(34,1,'New Foreign Star Of The Year - Actor'),(33,1,'New Foreign Star Of The Year - Actress'),(21,1,'New Star Of The Year'),(12,1,'New Star Of The Year - Actor'),(11,1,'New Star Of The Year - Actress'),(17,1,'Outstanding Use Of Color'),(4,1,'Picture'),(37,1,'Picture - Comedy'),(36,1,'Picture - Musical'),(7,1,'Promoting International Understanding'),(38,1,'Samuel Goldwyn International Award'),(8,1,'Special Achievement Award'),(31,1,'Television Achievement'),(61,1,'Television Movie'),(46,1,'Television Producer/Director'),(45,1,'Television Program'),(41,1,'Television Series'),(47,1,'Television Series - Comedy'),(49,1,'Television Series - Variety'),(71,1,'Television Special - Variety Or Musical'),(79,2,'Best Actor'),(80,2,'Best Actress'),(82,2,'Best Adapted Screenplay'),(110,2,'Best Animated Feature'),(89,2,'Best Animated Short'),(92,2,'Best Assistant Director'),(86,2,'Best Cinematography (Black and White)'),(100,2,'Best Cinematography (Color)'),(106,2,'Best Costume Design (Black and White)'),(107,2,'Best Costume Design (Color)'),(96,2,'Best Dance Direction'),(81,2,'Best Director'),(104,2,'Best Documentary Feature'),(103,2,'Best Documentary Short'),(95,2,'Best Film Editing'),(105,2,'Best International Feature Film'),(99,2,'Best Live Action Short (Color)'),(90,2,'Best Live Action Short (Comedy or One Reel or Regular)'),(91,2,'Best Live Action Short (Two-Reel or Novelty)'),(109,2,'Best Makeup and Hairstyling'),(101,2,'Best Original Musical/Secondary Score Category'),(83,2,'Best Original Screenplay'),(94,2,'Best Original Song'),(84,2,'Best Original Story'),(77,2,'Best Picture'),(85,2,'Best Production Design (Black and White)'),(102,2,'Best Production Design (Color)'),(93,2,'Best Score'),(108,2,'Best Sound Editing'),(88,2,'Best Sound Mixing'),(97,2,'Best Supporting Actor'),(98,2,'Best Supporting Actress'),(87,2,'Best Visual/Special Effects'),(78,2,'Unique and Artistic Production');
/*!40000 ALTER TABLE `award_categories` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-05-02 20:42:12
